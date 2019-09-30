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
      def start_timer
        sleep(@exception_flag ? @backoff_period : @flush_interval)
        flush
      end
      thread = Thread.new{ start_timer }
      thread.join
    end

    def write_to_buffer(msg, opts)
      if @lock.try_lock
        @buffer.concat(@side_messages) unless @side_messages.empty?
        processed_message = process_message(msg, opts)
        new_message_size = processed_message.to_s.bytesize

        @buffer_byte_size += new_message_size
        @buffer.push(processed_message)
      else
          @side_messages.push(process_message(msg, opts))
      end
      @lock.unlock if @lock.locked?

      flush if @flush_limit <= @buffer_byte_size
      schedule_flush unless @flush_scheduled
    end

    def send_request
      if !@lock.try_lock
        schedule_flush
      else
        @request.body = {
          e: "ls",
          ls: @buffer.concat(@side_messages)
        }.to_json
        @side_messages.clear

        handleExcpetion = lambda(message) do
          puts message
          @exception_flag = true
          @side_messages.concat(@buffer)
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
            puts "The response is not successful "
          end
          @exception_flag = false
        rescue SocketError
          handleExcpetion.call("Network connectivity issue")
        rescue Errno::ECONNREFUSED => e
          handleExcpetion.call("The server is down. #{e.message}")
        rescue Timeout::Error => e
          handleExcpetion.call("Timeout error occurred. #{e.message}")
        ensure
          @buffer.clear
          @lock.unlock if @lock.locked?
        end
      end
   end

    def flush
      @flush_scheduled = false
      return if @buffer.empty? && @side_messages.empty?

      send_request
    end

    def exitout
      flush if @buffer.any? || @side_messages.any?
      puts "Exiting LogDNA logger: Logging remaining messages"
      nil
    end
  end
end
