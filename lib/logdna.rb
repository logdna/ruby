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

        def trace(msg=nil, opts={})
            opts[:level] = "TRACE"
            loggerExist?
            optionChanged?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def debug(msg=nil, opts={})
            opts[:level] = "DEBUG"
            loggerExist?
            optionChanged?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def info(msg=nil, opts={})
            opts[:level] = "INFO"
            loggerExist?
            optionChanged?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def warn(msg=nil, opts={})
            opts[:level] = "WARN"
            loggerExist?
            optionChanged?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def error(msg=nil, opts={})
            opts[:level] = "ERROR"
            loggerExist?
            optionChanged?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def fatal(msg=nil, opts={})
            opts[:level] = "FATAL"
            loggerExist?
            optionChanged?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def trace?
            loggerExist?
            unless @level
                return 'TRACE' == @@client.getLevel
            end
            logLevel('TRACE')
        end

        def debug?
            loggerExist?
            unless @level
                return 'DEBUG' == @@client.getLevel
            end
            logLevel('DEBUG')
        end

        def info?
            loggerExist?
            unless @level
                return 'INFO' == @@client.getLevel
            end
            logLevel('INFO')
        end

        def warn?
            loggerExist?
            unless @level
                return 'WARN' == @@client.getLevel
            end
            logLevel('WARN')
        end

        def error?
            loggerExist?
            unless @level
                return 'ERROR' == @@client.getLevel
            end
            logLevel('ERROR')
        end

        def fatal?
            loggerExist?
            unless @level
                return 'FATAL' == @@client.getLevel
            end
            logLevel('FATAL')
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

