require 'logger'
require "socket"
require "uri"
require_relative "logdna/client.rb"
require_relative "logdna/resources.rb"
module Logdna
  class ValidURLRequired < ArgumentError; end
  class MaxLengthExceeded < ArgumentError; end

  class Ruby < ::Logger
    # uncomment line below and line 3 to enforce singleton
    # include Singleton
    Logger::TRACE = 5
    attr_accessor :level, :app, :env, :meta

    def initialize(key, opts = {})
      @app = opts[:app] || "default"
      @level = opts[:level] || "INFO"
      @env = opts[:env]
      @meta = opts[:meta]
      endpoint = opts[:endpoint] || Resources::ENDPOINT
      hostname = opts[:hostname] || Socket.gethostname

      if hostname.size > Resources::MAX_INPUT_LENGTH || @app.size > Resources::MAX_INPUT_LENGTH
        puts "Hostname or Appname is over #{Resources::MAX_INPUT_LENGTH} characters"
        return
      end

      ip =  opts.key?(:ip) ? "&ip=#{opts[:ip]}" : ""
      mac = opts.key?(:mac) ? "&mac=#{opts[:mac]}" : ""
      url = "#{endpoint}?hostname=#{hostname}#{mac}#{ip}"
      uri = URI(url)

      request = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
      request.basic_auth("username", key)

      @client = Logdna::Client.new(request, uri, opts)
    end

    def default_opts
      {
        app: @app,
        level: @level,
        env: @env,
        meta: @meta,
      }
    end

    def assign_level=(value)
      if value.is_a? Numeric
        @level = Resources::LOG_LEVELS[value]
        return
      end

      @level = value
    end

    def log(message = nil, opts = {})
      if message.nil? && block_given?
        message = yield
      end
      if message.nil?
        puts "provide either a message or block"
      end
      message = message.to_s.encode("UTF-8")
      @client.write_to_buffer(message, default_opts.merge(opts).merge(
                                         timestamp: (Time.now.to_f * 1000).to_i
                                       ))
    end

    Resources::LOG_LEVELS.each do |lvl|
      name = lvl.downcase

      define_method name do |msg = nil, opts = {}, &block|
        self.log(msg, opts.merge(
                        level: lvl
<<<<<<< HEAD
                      ), &block)
=======
                      ))
>>>>>>> rubocop
      end

      define_method "#{name}?" do
        return Resources::LOG_LEVELS[self.level] == lvl if level.is_a? Numeric

        self.level == lvl
      end
    end

    def clear
      @app = "default"
      @level = "INFO"
      @env = nil
      @meta = nil
    end

    def <<(msg = nil, opts = {})
      log(msg, opts.merge(
                 level: ""
               ))
    end

    def add(*_arg)
      puts "add not supported in LogDNA logger"
      false
    end

    def unknown(msg = nil, opts = {})
      log(msg, opts.merge(
                 level: "UNKNOWN"
               ))
    end

    def datetime_format(*_arg)
      puts "datetime_format not supported in LogDNA logger"
      false
    end

    def close
      if defined?(@client and !@@client.nil?)
        @client.exitout()
      end
    end

    def at_exit
      if defined?(@client && !@client.nil?)
        @client.exitout()
      end
    end

    def close
      @client.exitout if defined? @client && !@client.nil?
    end

    def at_exit
      @client.exitout if defined? @client && !@client.nil?
    end
  end
end


# require 'socket'
# puts "here?"
# loop {
#   msg = $stdin.gets
#
#   TCPSocket.open("localhost", 2000).puts(msg)
# }
