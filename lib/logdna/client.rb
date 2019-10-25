# frozen_string_literal: true

require "net/http"
require "socket"
require "json"
require "concurrent"
require "date"

module Logdna
  class Client
    def initialize(request, uri, opts)
      @uri = uri

      # NOTE: buffer is in memory
      @buffer = []
      @buffer_byte_size = 0

      @side_messages = []

      @lock = Mutex.new
      @side_message_lock = Mutex.new
      @flush_limit = opts[:flush_size] || Resources::FLUSH_BYTE_LIMIT
      @flush_interval = opts[:flush_interval] || Resources::FLUSH_INTERVAL
      @flush_scheduled = false
      @exception_flag = false

      @request = request
      @retry_timeout = opts[:retry_timeout] || Resources::RETRY_TIMEOUT

      @internal_logger = Logger.new(STDOUT)
      @internal_logger.level = Logger::DEBUG
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

    def schedule_flush
      start_timer = lambda {
        sleep(@exception_flag ? @retry_timeout : @flush_interval)
        flush if @flush_scheduled
      }
      thread = Thread.new { start_timer }
      thread.join
    end

    def write_to_buffer(msg, opts)
      if @lock.try_lock
        processed_message = process_message(msg, opts)
        new_message_size = processed_message.to_s.bytesize
        @buffer.push(processed_message)
        @buffer_byte_size += new_message_size
        @flush_scheduled = true
        @lock.unlock

        flush if @flush_limit <= @buffer_byte_size

        schedule_flush unless @flush_scheduled
      else
        @side_message_lock.synchronize do
          @side_messages.push(process_message(msg, opts))
        end
      end
      timer_task.execute
      timer_task
    end

    # This method has to be called with @lock
    def send_request
      puts "lll"
      @side_message_lock.synchronize do
        @buffer.concat(@side_messages)
        @side_messages.clear
      end

      @request.body = {
        e: "ls",
        ls: @buffer
      }.to_json

      handle_exception = lambda do |message|
        @internal_logger.debug(message)
        @exception_flag = true
        @side_message_lock.synchronize do
          @side_messages.concat(@buffer)
        rescue Timeout::Error => e
          puts "Timeout error occurred. #{e.message}"
          @exception_flag = true
          @side_messages.concat(@buffer)
        ensure
          @buffer.clear
        end
      end

      begin
        @response = Net::HTTP.start(
          @uri.hostname,
          @uri.port,
          use_ssl: @uri.scheme == "https"
        ) do |http|
          http.request(@request)
        end
        if @response.is_a?(Net::HTTPForbidden)
          @internal_logger.debug("Please provide a valid ingestion key")
        elsif !@response.is_a?(Net::HTTPSuccess)
          handle_exception.call("The response is not successful ")
        end
        @exception_flag = false
      rescue SocketError
        handle_exception.call("Network connectivity issue")
      rescue Errno::ECONNREFUSED => e
        handle_exception.call("The server is down. #{e.message}")
      rescue Timeout::Error => e
        handle_exception.call("Timeout error occurred. #{e.message}")
      ensure
        @buffer.clear
      end
    end

    def flush
      if @lock.try_lock
        @flush_scheduled = false
        if @buffer.any? || @side_messages.any?
          send_request
        end
        @lock.unlock
      else
        schedule_flush
      end
   end

    def exitout
      flush
      @internal_logger.debug("Exiting LogDNA logger: Logging remaining messages")
    end
  end
end
