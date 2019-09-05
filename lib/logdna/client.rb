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
      @flush_limit = opts[:flush_size] ? opts[:flush_size] : Resources::FLUSH_BYTE_LIMIT
      @flush_interval = opts[:flush_interval] ? opts[:flush_interval] : Resources::FLUSH_INTERVAL
      @flush_scheduled = false
      @exception_flag = false

      @request = request
      @retry_timeout = opts[:retry_timeout] ? opts[:retry_timeout] : Resources::RETRY_TIMEOUT
    end

    def process_message(msg, opts = {})
      processed_message = {
        line: msg,
        app: opts[:app],
        level: opts[:level],
        env: opts[:env],
        meta: opts[:meta],
        timestamp: Time.now.to_i
      }
      processed_message.delete(:meta) if processed_message[:meta].nil?
      processed_message
    end

    def schedule_flush
      @flush_scheduled = true
      start_timer = lambda {
        sleep(@exception_flag ? @retry_timeout : @flush_interval)
        flush
      }
      thread = Thread.new { start_timer }
      thread.join
    end

    def write_to_buffer(msg, opts)
      if @lock.try_lock
        @buffer.concat(@side_messages) unless @side_messages.empty?
        processed_message = process_message(msg, opts)
        new_message_size = processed_message.to_s.bytesize

        @buffer_byte_size += new_message_size
        @buffer.push(processed_message)

        @lock.unlock if @lock.locked?

        flush if @flush_limit <= @buffer_byte_size

        schedule_flush unless @flush_scheduled
      else
        @side_messages.push(process_message(msg, opts))
      end
    end

    def send_request
      @request.body = {
        e: "ls",
        ls: @buffer.concat(@side_messages)
      }.to_json
      @side_messages.clear

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
        puts "Network connectivity issue"
        @exception_flag = true
        @side_messages.concat(@buffer)
      rescue Errno::ECONNREFUSED => e
        puts "The server is down. #{e.message}"
        @exception_flag = true
        @side_messages.concat(@buffer)
      rescue Timeout::Error => e
        puts "Timeout error occurred. #{e.message}"
        @exception_flag = true
        @side_messages.concat(@buffer)
      ensure
        @buffer.clear
        @lock.unlock if @lock.locked?
      end
    end

    def flush
      @flush_scheduled = false
      return if @buffer.empty?

      if @lock.try_lock
        send_request
      else
        schedule_flush
      end
    end

    def exitout
      flush if @buffer.any?
      puts "Exiting LogDNA logger: Logging remaining messages"
      nil
    end
  end
end
