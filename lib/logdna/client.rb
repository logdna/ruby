require 'net/http'
require 'socket'
require 'json'
require 'concurrent'
require 'thread'
module Logdna
  class Client < Thread

    def initialize(request, uri, opts)
      super do
        @uri = uri
        # NOTE: buffer is in memory
        @buffer = StringIO.new
        @buffer_over_limit = false
        @messages = []

        @lock = Mutex.new
        @task = nil

        # NOTE: the byte limit only affects the message, not the entire message_hash
        @actual_byte_limit = opts[:flushbyte] ||= Resources::FLUSH_BYTE_LIMIT
        @actual_flush_interval = opts[:flushtime] ||= Resources::FLUSH_INTERVAL

        @@request = request
      end
    end

    def encode_message(msg)
      msg = msg.to_s unless msg.instance_of? String

      begin
          msg = msg.encode("UTF-8")
      rescue Encoding::UndefinedConversionError => e
        # NOTE: should this be raised or handled silently?
        raise e
      end
      msg
    end

    def message_hash(msg, opts={})
      {
        line: msg,
        app: opts[:app],
        level: opts[:level],
        env: opts[:env],
        timestamp: Time.now.to_i,
      }.reject { |_,v| v.nil? }
    end

    def create_flush_task
      t = Concurrent::TimerTask.new(execution_interval: @actual_flush_interval, timeout_interval: Resources::TIMER_OUT) do |task|
        if @messages.any?
          # keep running if there are queued messages, but don't flush
          # because the buffer is being flushed due to being over the limit
          unless @buffer_over_limit
            flush()
          end
        else
          # no messages means we can kill the task
          task.kill
        end
      end
      t.execute
    end

    # this should always be running synchronously within this thread
    def buffer(msg, opts)
      return if msg.nil?
      msg = encode_message(msg)

      buffer_size = @buffer.write(msg)
      @messages.push(message_hash(msg, opts))

      if buffer_size > @actual_byte_limit
        @buffer_over_limit = true
        flush()
        @buffer_over_limit = false
      else
        if @task.nil? or !@task.running?
          @task = create_flush_task
        end
      end
    end

    # this should be running synchronously if @buffer_over_limit i.e. called from self.buffer
    # else asynchronously through @task
    def flush()
      if defined? @@request and !@@request.nil?
        request_messages = []
        @lock.synchronize do
          request_messages = @messages
          @buffer.truncate(0)
          @messages = []
        end
        return if request_messages.empty?

        real = {
          e: 'ls',
          ls: request_messages,
        }.to_json

        @@request.body = real
        @response = Net::HTTP.start(@uri.hostname, @uri.port, use_ssl: @uri.scheme == 'https') do |http|
          http.request(@@request)
        end

        puts "Result: #{@response.body}" unless request_messages.empty?

        # don't kill @task if this was executed from self.buffer
        # don't kill @task if there are queued messages
        unless @buffer_over_limit || @messages.any? || @task.nil?
          @task.shutdown
          @task.kill
        end
      end
    end

    def exitout()
      if @messages.any?
        flush()
      end
      join
      puts "Exiting LogDNA logger: Logging remaining messages"
      return
    end
  end
end
