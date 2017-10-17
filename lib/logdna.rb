#!/usr/bin/env ruby
# encoding: utf-8
require 'socket'
require_relative 'logdna/client.rb'
require_relative 'logdna/resources.rb'
module Logdna
    class Ruby < ::Logger
        Logger::TRACE = 5
        attr_accessor :level, :app, :env, :meta
        @level = nil
        @app = nil
        @env = nil
        @meta = nil

        def initialize(key, opts={})
            @@client = true
            @@client = Logdna::Client.new(key, opts)
            sleep 0.01

            if @@client[:value] === Resources::LOGGER_NOT_CREATED
                @@client = nil
                puts "LogDNA logger not created"
                return
            end
        end

        def log(msg=nil, opts={})
            loggerExist?
            optionChanged?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        Resources::LOG_LEVELS.each do |level|
          name = level.downcase

          define_method name do |msg=nil, opts={}|
            opts[:level] = level
            loggerExist?
            optionChanged?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
          end

          define_method "#{name}?" do
            loggerExist?
            unless @level
                return level == @@client.getLevel
            end
            logLevel(level)
          end
        end

        def clear
            loggerExist?
            @@client.clear()
            @level = nil
            @app = nil
            @env = nil
            @meta = nil
            return true
        end

        def loggerExist?
            if @@client.nil?
                puts "Logger Not Initialized Yet"
                close
            end
        end

        def optionChanged?
            if @level || @app || @env || @meta
                @@client.change(@level, @app, @env, @meta)
                @level = nil
                @app = nil
                @env = nil
                @meta = nil
            end
        end

        def logLevel(comparedTo)
            if @level.is_a? Numeric
                @level = Resources::LOG_LEVELS[@level]
            end
            return comparedTo == @level.upcase
        end

        def <<(msg=nil, opts={})
            opts[:level] = ""
            loggerExist?
            optionChanged?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def add(*arg)
            puts "add not supported in LogDNA logger"
            return false
        end

        def unknown(msg=nil, opts={})
            opts[:level] = "UNKNOWN"
            loggerExist?
            optionChanged?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def datetime_format(*arg)
            puts "datetime_format not supported in LogDNA logger"
            return false
        end


        def close
            if defined? @@client
                @@client.exitout()
            end
            exit!
        end

        at_exit do
            if defined? @@client
                @@client.exitout()
            end
            exit!
        end
    end
end
