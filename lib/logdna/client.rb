require 'net/http'
require 'uri'
require 'socket'
require 'json'
require 'concurrent'
require 'thread'
module Logdna
    class Client < Thread

        class ValidURLRequired < ArgumentError; end
        class MaxLengthExceeded < ArgumentError; end

        def initialize(key, opts)
            super do
                hostname = (opts[:hostname] ||= Socket.gethostname),
                ip =  opts.key?(:ip) ? "&ip=#{opts[:ip]}" : '',
                mac = opts.key?(:mac) ? "&mac=#{opts[:mac]}" : '',

                begin
                    if (hostname.size > Resources::MAX_INPUT_LENGTH || opts[:app].size > Resources::MAX_INPUT_LENGTH )
                        raise MaxLengthExceeded.new
                    end
                rescue MaxLengthExceeded => e
                    puts "Hostname or Appname is over #{Resources::MAX_INPUT_LENGTH} characters"
                    self[:value] = Resources::LOGGER_NOT_CREATED
                    return
                end

                @firstbuff = []
                @secondbuff = []
                @currentbytesize = 0
                @secondbytesize = 0
                @actual_flush_interval = opts[:flushtime] ||= Resources::FLUSH_INTERVAL
                @actual_byte_limit = opts[:flushbyte] ||= Resources::FLUSH_BYTE_LIMIT

                @url = "#{Resources::ENDPOINT}?hostname=#{hostname}#{mac}#{:ip}"
                @@semaphore = Mutex.new
                begin
                    @uri = URI(@url)
                rescue URI::ValidURIRequired => e
                    raise ValidURLRequired.new("Invalid URL Endpoint: #{@url}")
                    self[:value] = Resources::LOGGER_NOT_CREATED
                    return
                end

                @@request = Net::HTTP::Post.new(@uri, 'Content-Type' => 'application/json')
                @@request.basic_auth 'username', key
                self[:value] = Resources::LOGGER_CREATED
            end
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

        def tobuffer(msg, opts)
            unless msg.nil?
                if @task
                    unless @task.running?
                        @task = Concurrent::TimerTask.new(execution_interval: @actual_flush_interval, timeout_interval: Resources::TIMER_OUT){ flush() }
                        @task.execute
                    end
                else
                    @task = Concurrent::TimerTask.new(execution_interval: @actual_flush_interval, timeout_interval: Resources::TIMER_OUT){ flush() }
                    @task.execute
                end

                unless msg.instance_of? String
                    msg = msg.to_s
                end

                begin
                    msg = msg.encode("UTF-8")
                rescue Encoding::UndefinedConversionError => e
                    raise e
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
        end

        def flush()
            if defined? @@request
                @@semaphore.synchronize {
                    real = {:e => 'ls', :ls => @firstbuff }.to_json
                    @@request.body = real
                    @response = Net::HTTP.start(@uri.hostname, @uri.port, :use_ssl => @uri.scheme == 'https') do |http|
                      http.request(@@request)
                    end
                    unless @firstbuff.empty?
                        puts "Result: #{@response.body}"
                    end
                    @currentbytesize = @secondbytesize
                    @secondbytesize = 0
                    @firstbuff = []
                    @firstbuff = @firstbuff + @secondbuff
                    @secondbuff = []
                    unless @task.nil?
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
