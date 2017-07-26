#!/usr/bin/env ruby
# encoding: utf-8
require 'socket'
require_relative 'logdna/client.rb'
require_relative 'logdna/resources.rb'
module Logdna
    class Ruby
        def initialize(key, opts={})
            @@client = Logdna::Client.new(key, opts)
            sleep 0.0001
            if @@client[:value] === Resources::LOGGER_NOT_CREATED
                @@client = nil
                puts "LogDNA logger not created"
                return
            end
        end

        def log(msg, opts={})
            if @@client === nil
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

