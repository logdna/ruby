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

      @@request = request
      @timer_task = false
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
      puts "calls"
      timer_task = Concurrent::TimerTask.new(execution_interval: @flush_interval, timeout_interval: Resources::TIMER_OUT) do |task|
          puts 'executing'
          self.flush
      end
      timer_task.execute
      timer_task
    end

    def write_to_buffer(msg, opts)
      puts 'log received'
      if @lock.try_lock
          if !@side_messages.empty?
            @buffer.concat(@side_messages)
          end

          if @timer_task == false
            @timer_task = Thread.new { self.create_flush_task }
            @timer_task.join
            puts "inside if block"
            puts @timer_task.status
          end
          puts "in buffer method"
          puts @timer_task.status
          processes_message = process_message(msg, opts)
          new_message_size = processes_message.to_s.bytesize
          @buffer_byte_size += new_message_size

          if @flush_limit > (new_message_size + @buffer_byte_size)
            @buffer.push(processes_message)
          else
            puts "calls from here?"
             @buffer.push(processes_message)
             self.flush
          end
      else
          @side_messages.push(process_message(msg, opts))
      end

    # this should be running synchronously if @buffer_over_limit i.e. called from self.buffer
    # else asynchronously through @task
    def flush
      puts "in flush method"
      puts @timer_task.status
      return if @buffer.empty?
      @@request.body = {
        e: 'ls',
        ls: @buffer,
      }.to_json

      @buffer.clear
    #  @timer_task.shutdown if !@timer_task.nil?
      puts 'log is flushed'
      @response = Net::HTTP.start(@uri.hostname, @uri.port, use_ssl: @uri.scheme == 'https') do |http|
        http.request(@@request)
      end

      if @response.code != '200'
        @buffer.concat(@@request.ls)
        @@request.body = nil
        # check what is request and clear it if still contains data
        puts `Error at the attempt to send the request #{@response.body}`
      end

      begin
        @lock.unlock
      rescue
        puts 'Nothing was locked'
      end
    end

    def exitout
      puts @timer_task.status
      if @buffer.any?
        flush()
      end
      puts "Exiting LogDNA logger: Logging remaining messages"
    end
  end
end
