# frozen_string_literal: true

require "etc"
require "net/http"
require "socket"
require "json"
require "concurrent"
require "date"
require "securerandom"

module Logdna
  Message = Struct.new(:source, :running_size)

  class Client
    def initialize(request, uri, opts)
      @uri = uri

      # NOTE: buffer is in memory
      @buffer = []

      @lock = Mutex.new

      @flush_interval = opts[:flush_interval] || Resources::FLUSH_INTERVAL
      @flush_size = opts[:flush_size] || Resources::FLUSH_SIZE

      @request = request
      @request_size = opts[:request_size] || Resources::REQUEST_SIZE

      @retry_timeout = opts[:retry_timeout] || Resources::RETRY_TIMEOUT
      @retry_max_jitter = opts[:retry_max_jitter] || Resources::RETRY_MAX_JITTER
      @retry_max_attempts = opts[:retry_max_attempts] || Resources::RETRY_MAX_ATTEMPTS

      @internal_logger = Logger.new($stdout)
      @internal_logger.level = Logger::DEBUG

      @work_thread_pool = Concurrent::FixedThreadPool.new(Etc.nprocessors)
      # TODO: Expose an option to configure the maximum concurrent requests
      # Requires the instance-global request to be resolved first
      @request_thread_pool = Concurrent::FixedThreadPool.new(Resources::MAX_CONCURRENT_REQUESTS)

      @scheduled_flush = nil
    end

    def schedule_flush
      if @scheduled_flush.nil? || @scheduled_flush.complete?
        @scheduled_flush = Concurrent::ScheduledTask.execute(@flush_interval) { flush }
      end
    end

    def unschedule_flush
      if !@scheduled_flush.nil?
        @scheduled_flush.cancel
        @scheduled_flush = nil
      end
    end

    def process_message(msg, opts = {})
      processed_message = {
        line: msg,
        app: opts[:app],
        level: opts[:level],
        env: opts[:env],
        meta: opts[:meta],
        timestamp: Time.now.to_i,
      }
      processed_message.delete(:meta) if processed_message[:meta].nil?
      processed_message
    end

    def write_to_buffer(msg, opts)
      Concurrent::Future.execute({ executor: @work_thread_pool }) { write_to_buffer_sync(msg, opts) }
    end

    def write_to_buffer_sync(msg, opts)
      processed_message = process_message(msg, opts)
      message_size = processed_message.to_s.bytesize

      running_size = @lock.synchronize do
        running_size = message_size
        if @buffer.any?
          running_size += @buffer[-1].running_size
        end
        @buffer.push(Message.new(processed_message, running_size))

        running_size
      end

      if running_size >= @flush_size
        unschedule_flush
        flush_sync
      else
        schedule_flush
      end
    end

    ##
    # Flushes all logs to LogDNA asynchronously
    def flush(options = {})
      Concurrent::Future.execute({ executor: @work_thread_pool }) { flush_sync(options) }
    end

    ##
    # Flushes all logs to LogDNA synchronously
    def flush_sync(options = {})
      slices = @lock.synchronize do
        # Slice the buffer into chunks that try to be no larger than @request_size. Slice points are found with
        # a binary search thanks to the structure of @buffer. We are working backwards because it's cheaper to
        # remove from the tail of an array instead of the head
        slices = []
        until @buffer.empty?
          search_size = @buffer[-1].running_size - @request_size
          if search_size.negative?
            search_size = 0
          end

          slice_index = @buffer.bsearch_index { |message| message.running_size >= search_size }
          slices.push(@buffer.pop(@buffer.length - slice_index).map(&:source))
        end
        slices
      end

      # Remember the chunks are in reverse order, this un-reverses them
      slices.reverse_each do |slice|
        if options[:block_on_requests]
          try_request(slice)
        else
          Concurrent::Future.execute({ executor: @request_thread_pool }) { try_request(slice) }
        end
      end
    end

    def try_request(slice)
      body = {
        e: "ls",
        ls: slice
      }.to_json

      flush_id = "#{SecureRandom.uuid} [#{slice.length} lines]"
      error_header = "Flush {#{flush_id}} failed."
      tries = 0
      loop do
        tries += 1

        if tries > @retry_max_attempts
          @internal_logger.debug("Flush {#{flush_id}} exceeded 3 tries. Discarding flush buffer")
          break
        end

        if send_request(body, error_header)
          break
        end

        sleep(@retry_timeout * (1 << (tries - 1)) + rand(@retry_max_jitter))
      end
    end

    def send_request(body, error_header)
      # TODO: Remove instance-global request object
      @request.body = body
      begin
        response = Net::HTTP.start(
          @uri.hostname,
          @uri.port,
          use_ssl: @uri.scheme == "https"
        ) do |http|
          http.request(@request)
        end

        code = response.code.to_i
        if [401, 403].include?(code)
          @internal_logger.debug("#{error_header} Please provide a valid ingestion key. Discarding flush buffer")
          return true
        elsif [408, 500, 504].include?(code)
          # These codes might indicate a temporary ingester issue
          @internal_logger.debug("#{error_header} The request failed #{response}. Retrying")
        elsif code == 200
          return true
        else
          @internal_logger.debug("#{error_header} The request failed #{response}. Discarding flush buffer")
          return true
        end
      rescue SocketError
        @internal_logger.debug("#{error_header} Network connectivity issue. Retrying")
      rescue Errno::ECONNREFUSED => e
        @internal_logger.debug("#{error_header} The server is down. #{e.message}. Retrying")
      rescue Timeout::Error => e
        @internal_logger.debug("#{error_header} Timeout error occurred. #{e.message}. Retrying")
      end

      false
    end

    def exitout
      unschedule_flush
      @work_thread_pool.shutdown
      if !@work_thread_pool.wait_for_termination(1)
        @internal_logger.warn("Work thread pool unable to shutdown gracefully. Logs potentially dropped")
      end
      @request_thread_pool.shutdown
      if !@request_thread_pool.wait_for_termination(5)
        @internal_logger.warn("Request thread pool unable to shutdown gracefully. Logs potentially dropped")
      end

      if @buffer.any?
        @internal_logger.debug("Exiting LogDNA logger: Logging remaining messages")
        flush_sync({ block_on_requests: true })
        @internal_logger.debug("Finished flushing logs to LogDNA")
      end
    end
  end
end
