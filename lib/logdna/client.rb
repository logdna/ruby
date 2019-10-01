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
      @flush_scheduled = true
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
        @lock.unlock

        flush if @flush_limit <= @buffer_byte_size
        schedule_flush unless @flush_scheduled
      else
        @side_message_lock.synchronize do
          @side_messages.push(process_message(msg, opts))
        end
      end
    end

    def send_request
        @side_message_lock.synchronize do
          @buffer.concat(@side_messages)
          @side_messages.clear
        end

        @request.body = {
          e: "ls",
          ls: @buffer
        }.to_json

        handleExcpetion = lambda do |message|
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
        end
    end

    def flush
      @flush_scheduled = false
      if @lock.try_lock
        return if @buffer.empty? && @side_messages.empty?
        send_request
        @lock.unlock
      else
        schedule_flush
      end
    end

    def exitout
      flush if @buffer.any? || @side_messages.any?
      puts "Exiting LogDNA logger: Logging remaining messages"
      nil
    end
  end
end
