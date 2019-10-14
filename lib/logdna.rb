#!/usr/bin/env ruby
# encoding: utf-8
# require 'singleton'
require 'socket'
require 'uri'
require_relative 'logdna/client.rb'
require_relative 'logdna/resources.rb'
module Logdna
  class ValidURLRequired < ArgumentError; end
  class MaxLengthExceeded < ArgumentError; end

  class Ruby < ::Logger
    # uncomment line below and line 3 to enforce singleton
    # include Singleton
    Logger::TRACE = 5
    attr_accessor :level, :app, :env, :meta

    def initialize(key, opts={})
      @app = opts[:app] || 'default'
      @level = opts[:level] || 'INFO'
      @env = opts[:env]
      @meta = opts[:meta]
      @@client = nil unless defined? @@client

      endpoint = opts[:endpoint] || Resources::ENDPOINT
      hostname = opts[:hostname] || Socket.gethostname
      ip =  opts.key?(:ip) ? "&ip=#{opts[:ip]}" : ''
      mac = opts.key?(:mac) ? "&mac=#{opts[:mac]}" : ''
      url = "#{endpoint}?hostname=#{hostname}#{mac}#{ip}"

      begin
        if (hostname.size > Resources::MAX_INPUT_LENGTH || @app.size > Resources::MAX_INPUT_LENGTH )
            raise MaxLengthExceeded.new
        end
      rescue MaxLengthExceeded => e
        puts "Hostname or Appname is over #{Resources::MAX_INPUT_LENGTH} characters"
        handle_exception(e)
        return
      end

      begin
        uri = URI(url)
      rescue URI::ValidURIRequired => e
        puts "Invalid URL Endpoint: #{url}"
        handle_exception(e)
        return
      end

      begin
        request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
        request.basic_auth 'username', key
        request[:'user-agent'] = opts[:'user-agent'] || "ruby/#{LogDNA::VERSION}"
      rescue => e
        handle_exception(e)
        return
      end

      @@client = Logdna::Client.new(request, uri, opts)
    end

    def handle_exception(e)
      exception_message = e.message
      exception_backtrace = e.backtrace
      # NOTE: should log with Ruby logger?
      puts exception_message
    end

    def default_opts
      {
        app: @app,
        level: @level,
        env: @env,
        meta: @meta,
      }
    end

    def level=(value)
      if value.is_a? Numeric
        @level = Resources::LOG_LEVELS[value]
        return
      end

      @level = value
    end

    def log(msg=nil, opts={})
      loggerExist?
      message = msg
      message = yield if msg.nil? && block_given?
      @response = @@client.buffer(message, default_opts.merge(opts).merge({
            timestamp: (Time.now.to_f * 1000).to_i
        }))
      'Saved'
    end

    Resources::LOG_LEVELS.each do |lvl|
      name = lvl.downcase

      define_method name do |msg=nil, opts={}, &block|
        self.log(msg, opts.merge({
          level: lvl,
        }), &block)
      end

      define_method "#{name}?" do
        return Resources::LOG_LEVELS[self.level] == lvl if self.level.is_a? Numeric
        self.level == lvl
      end
    end

    def clear
      @app = 'default'
      @level = 'INFO'
      @env = nil
      @meta = nil
    end

    def loggerExist?
      if @@client.nil?
        puts "Logger Not Initialized Yet"
        close
      end
    end

    def <<(msg=nil, opts={})
      self.log(msg, opts.merge({
        level: '',
      }))
    end

    def add(*arg)
      puts "add not supported in LogDNA logger"
      return false
    end

    def unknown(msg=nil, opts={})
      self.log(msg, opts.merge({
        level: 'UNKNOWN',
      }))
    end

    def datetime_format(*arg)
      puts "datetime_format not supported in LogDNA logger"
      return false
    end


    def close
      if defined? @@client and !@@client.nil?
          @@client.exitout()
      end
    end

    at_exit do
      if defined? @@client and !@@client.nil?
          @@client.exitout()
      end
    end
  end
end
