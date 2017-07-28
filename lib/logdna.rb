#!/usr/bin/env ruby
# encoding: utf-8
require 'socket'
require_relative 'logdna/client.rb'
require_relative 'logdna/resources.rb'
module Logdna
    class Ruby
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

            if @@client.nil?
                puts "Logger Not Initialized Yet"
                return
            end
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end


        def trace(msg, opts={})
            opts[:level] = "TRACE"
            if @@client.nil?
                puts "Logger Not Initialized Yet"
                return
            end
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def debug(msg, opts={})
            opts[:level] = "DEBUG"
            if @@client.nil?
                puts "Logger Not Initialized Yet"
                return
            end
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def info(msg, opts={})
            opts[:level] = "INFO"
            if @@client.nil?
                puts "Logger Not Initialized Yet"
                return
            end
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def warn(msg, opts={})
            opts[:level] = "WARN"
            if @@client.nil?
                puts "Logger Not Initialized Yet"
                return
            end
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def error(msg, opts={})
            opts[:level] = "ERROR"
            if @@client.nil?
                puts "Logger Not Initialized Yet"
                return
            end
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end

        def fatal(msg, opts={})
            opts[:level] = "FATAL"
            if @@client.nil?
                puts "Logger Not Initialized Yet"
                return
            end
            @response = @@client.tobuffer(msg, opts)
            'Saved'
        end



        at_exit do
            if defined? @@client
                @@client.exitout()
            end
            exit!
        end
    end
end

