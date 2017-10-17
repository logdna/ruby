require 'net/http'
require 'socket'
require 'json'
require 'concurrent'
require 'thread'
module Logdna
    class Client < Thread

        class ValidURLRequired < ArgumentError; end
        class MaxLengthExceeded < ArgumentError; end

        def initialize(request, uri, opts)
            super do
                @uri = uri
                @firstbuff = []
                @secondbuff = []
                @currentbytesize = 0
                @secondbytesize = 0
                @actual_flush_interval = opts[:flushtime] ||= Resources::FLUSH_INTERVAL
                @actual_byte_limit = opts[:flushbyte] ||= Resources::FLUSH_BYTE_LIMIT

                @@semaphore = Mutex.new
                @@request = request
            end
        end

        def encode_message(msg)
          msg = msg.to_s unless msg.instance_of? String

          begin
              msg = msg.encode("UTF-8")
          rescue Encoding::UndefinedConversionError => e
            # should this be raised or handled silently?
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
          Concurrent::TimerTask.new(execution_interval: @actual_flush_interval, timeout_interval: Resources::TIMER_OUT){ flush() }
        end

        def buffer(msg, opts)
          return if msg.nil?
          msg = encode_message(msg)

          unless @task.present? and @task.running?
            @task = create_flush_task
          end

          unless @@semaphore.locked?
            @currentbytesize += msg.bytesize
            @firstbuff.push(message_hash(msg, opts))
          else
            @secondbytesize += msg.bytesize
            @secondbuff.push(message_hash(msg, opts))
          end

          if @actual_byte_limit < @currentbytesize
            flush()
          end
        end

        def flush()
          if defined? @@request and @@request.present?
            @@semaphore.synchronize {
              real = {
                e: 'ls',
                ls: @firstbuff,
              }.to_json

              @@request.body = real
              @response = Net::HTTP.start(@uri.hostname, @uri.port, use_ssl: @uri.scheme == 'https') do |http|
                http.request(@@request)
              end

              puts "Result: #{@response.body}" unless @firstbuff.empty?

              @currentbytesize = @secondbytesize
              @secondbytesize = 0
              @firstbuff = []
              @firstbuff = @firstbuff + @secondbuff
              @secondbuff = []
              if @task.present?
                @task.shutdown
                @task.kill
              end
            }
          end
        end

        def exitout()
            flush()
            join
            puts "Exiting LogDNA logger: Logging remaining messages"
            return
        end
    end
end
