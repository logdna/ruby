require 'net/http'
require 'socket'
require 'json'
require 'concurrent'
require 'thread'
require 'date'

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
    end

    def process_message(msg, opts={})
      processedMessage = {
        line: msg,
        app: opts[:app],
        level: opts[:level],
        env: opts[:env],
        meta: opts[:meta],
        timestamp: Time.now.to_i,
      }
      processedMessage.delete(:meta) if processedMessage[:meta].nil?
      processedMessage
    end

    def create_flush_task
        timer_task = Concurrent::TimerTask.new(execution_interval: @flush_interval, timeout_interval: Resources::TIMER_OUT) do |task|
            puts 'executing'
            self.flush
        end
        timer_task.execute
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
    end

    # This method has to be called with @lock
    def send_request
      @side_message_lock.synchronize do
        @buffer.concat(@side_messages)
        @side_messages.clear
      end

      @request.body = {
        e: "ls",
        ls: @buffer
      }.to_json

      handle_exception = lambda do |message|
        puts message
        @exception_flag = true
        @side_message_lock.synchronize do
          @side_messages.concat(@buffer)
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
          puts "Please provide a valid ingestion key"
        elsif !@response.is_a?(Net::HTTPSuccess)
          handle_exception.call("The response is not successful ")
        end
        @exception_flag = false
        p @response
      rescue SocketError
        handle_exception.call("Network connectivity issue")
      rescue Errno::ECONNREFUSED => e
        handle_exception.call("The server is down. #{e.message}")
      rescue Timeout::Error => e
        handle_exception.call("Timeout error occurred. #{e.message}")
      rescue
        handle_exception.call("#{e.message}")
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
      puts "Exiting LogDNA logger: Logging remaining messages"
    end
  end
end
