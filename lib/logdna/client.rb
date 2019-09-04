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
      @flush_limit = opts[:flush_size] ||= Resources::FLUSH_BYTE_LIMIT
      @flush_interval = opts[:flush_interval] ||= Resources::FLUSH_INTERVAL
      @flush_scheduled = false
      @exception_flag = false

      @request = request
      @retry_timeout = opts[:retry_timeout] ||= Resources::RETRY_TIMEOUT
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

    def schedule_flush
      @flush_scheduled = true
      def start_timer
        sleep(@exception_flag ? @retry_timeout : @flush_interval)
        flush
      end
      thread = Thread.new{ start_timer }
      thread.join
    end

    def write_to_buffer(msg, opts)
      if @lock.try_lock
          if !@side_messages.empty?
            @buffer.concat(@side_messages)
          end
          processed_message = process_message(msg, opts)
          new_message_size = processed_message.to_s.bytesize
          @buffer_byte_size += new_message_size

          if @flush_limit > (new_message_size + @buffer_byte_size)
             @buffer.push(processed_message)
          else
             @buffer.push(processed_message)
             self.flush
          end
          @lock.unlock if @lock.locked?

          schedule_flush() if !@flush_scheduled
      else
          @side_messages.push(process_message(msg, opts))
      end
    end

    def flush
      return if @buffer.empty?
      if @lock.try_lock
        @request.body = {
          e: 'ls',
          ls: @buffer.concat(@side_messages),
        }.to_json
        @side_messages.clear

        begin
          @response = Net::HTTP.start(@uri.hostname, @uri.port, use_ssl: @uri.scheme == 'https') do |http|
            http.request(@request)
          end
          @exception_flag = false
        rescue
          p "Error at the attempt to send the request #{@response.body if @response}"
          @exception_flag = true
          @side_messages.concat(@buffer)
        end
        @flush_scheduled = false
        @buffer.clear

        @lock.unlock if @lock.locked?
      end
   end

   def exitout
      if @buffer.any?
        flush()
      end
        puts "Exiting LogDNA logger: Logging remaining messages"
      return
    end
  end
end
