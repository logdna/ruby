#!/usr/bin/env ruby
# encoding: utf-8
require 'socket'
require_relative 'logdna/client.rb'
require_relative 'logdna/resources.rb'
module Logdna
    class Ruby < ::Logger
        Logger::TRACE = 5
        attr_accessor :level, :app, :env
        @level = nil
        @app = nil
        @env = nil

        def initialize(key, opts={})
            @@client = Logdna::Client.new(key, opts)
            sleep 0.01

            if @@client[:value] === Resources::LOGGER_NOT_CREATED
                @@client = nil
                puts "LogDNA logger not created"
                return
            end
        end

        def log(msg, opts={})
            if @level || @app || @env
                @@client.change(@level, @app, @env)
                @level = nil
                @app = nil
                @env = nil
            end

            loggerExist?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def trace(msg, opts={})
            opts[:level] = "TRACE"
            loggerExist?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def debug(msg, opts={})
            opts[:level] = "DEBUG"
            loggerExist?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def info(msg, opts={})
            opts[:level] = "INFO"
            loggerExist?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def warn(msg, opts={})
            opts[:level] = "WARN"
            loggerExist?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def error(msg, opts={})
            opts[:level] = "ERROR"
            loggerExist?
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def fatal(msg, opts={})
            opts[:level] = "FATAL"
            loggerExist?
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

        def loggerExist?
            if @@client.nil?
                puts "Logger Not Initialized Yet"
                close
            end
        end

        def logLevel(comparedTo)
            if @level.is_a? Numeric
                @level = Resources::LOG_LEVELS[@level]
            end
            return comparedTo == @level.upcase
        end

        def <<(*arg)
            puts "<< not supported in LogDNA logger"
            return false
        end

        def add(*arg)
            puts "add not supported in LogDNA logger"
            return false
        end

        def unknown(*arg)
            puts "unknown not supported in LogDNA logger"
            return false
        end

        def datetime_format(*arg)
            puts "datetime_format not supported in LogDNA logger"
            return false
        end


        def close
            if @@client
                @@client.exitout()
            end
            exit!
        end

        at_exit do
            if @@client
                @@client.exitout()
            end
            exit!
        end
    end
end

