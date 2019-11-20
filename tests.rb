# frozen_string_literal: true

require "minitest/autorun"

require_relative "lib/logdna.rb"
require_relative "lib/logdna/client.rb"
require_relative "test_server.rb"

class TestLogDNARuby < Minitest::Test
  LOG_LINE = "log line"

  def get_options(port)
    {
      hostname: "rubyTestHost",
      ip: "75.10.4.81",
      mac: "00:00:00:a1:2b:cc",
      app: "rubyApplication",
      level: "INFO",
      env: "PRODUCTION",
      endpoint: "http://localhost:#{port}",
      flush_interval: 1,
      flush_size: 5,
      retry_timeout: 1
    }
  end

  def warn_method(port)
    options = get_options(port)
    logdna_thread = Thread.start do
      logger = Logdna::Ruby.new("pp", options)
      logger.warn(LOG_LINE)
    end

    server_thread = Thread.start do
      server = TestServer.new
      recieved_data = server.start_server(port)

      assert_equal(recieved_data[:ls][0][:line], LOG_LINE)
      assert_equal(recieved_data[:ls][0][:app], options[:app])
      assert_equal(recieved_data[:ls][0][:level], "WARN")
      assert_equal(recieved_data[:ls][0][:env], options[:env])
    end

    logdna_thread.join
    server_thread.join
  end

  def info_method(port)
    options = get_options(port)
    logdna_thread = Thread.start do
      logger = Logdna::Ruby.new("pp", options)
      logger.info(LOG_LINE)
    end

    server_thread = Thread.start do
      sor = TestServer.new
      recieved_data = sor.start_server(port)

      assert_equal(recieved_data[:ls][0][:line], LOG_LINE)
      assert_equal(recieved_data[:ls][0][:app], options[:app])
      assert_equal(recieved_data[:ls][0][:level], "INFO")
      assert_equal(recieved_data[:ls][0][:env], options[:env])
    end

    logdna_thread.join
    server_thread.join
  end

  def debug_method(port)
    options = get_options(port)
    logdna_thread = Thread.start do
      logger = Logdna::Ruby.new("pp", options)
      logger.debug(LOG_LINE)
    end

    server_thread = Thread.start do
      sor = TestServer.new
      recieved_data = sor.start_server(port)

      assert_equal(recieved_data[:ls][0][:line], LOG_LINE)
      assert_equal(recieved_data[:ls][0][:app], options[:app])
      assert_equal(recieved_data[:ls][0][:level], "DEBUG")
      assert_equal(recieved_data[:ls][0][:env], options[:env])
    end

    logdna_thread.join
    server_thread.join
  end

  def fatal_method(port)
    options = get_options(port)
    logdna_thread = Thread.start do
      logger = Logdna::Ruby.new("pp", options)
      logger.fatal(LOG_LINE)
    end

    server_thread = Thread.start do
      sor = TestServer.new
      recieved_data = sor.start_server(port)

      assert_equal(recieved_data[:ls][0][:line], LOG_LINE)
      assert_equal(recieved_data[:ls][0][:app], options[:app])
      assert_equal(recieved_data[:ls][0][:level], "FATAL")
      assert_equal(recieved_data[:ls][0][:env], options[:env])
    end

    logdna_thread.join
    server_thread.join
  end

  # Should retry to connect and preserve the failed line
  def fatal_method_not_found(port)
    second_line = " second line"
    options = get_options(port)
    logdna_thread = Thread.start do
      logger = Logdna::Ruby.new("pp", options)
      logger.fatal(LOG_LINE)
      logger.fatal(second_line)
    end

    server_thread = Thread.start do
      sor = TestServer.new
      recieved_data = sor.return_not_found_res(port)
      # The order of recieved lines is unpredictable.
      recieved_lines = [
        recieved_data[:ls][0][:line],
        recieved_data[:ls][1][:line]
      ]

      assert_includes(recieved_lines, LOG_LINE)
      assert_includes(recieved_lines, second_line)

      assert_equal(recieved_data[:ls][0][:app], options[:app])
      assert_equal(recieved_data[:ls][0][:level], "FATAL")
      assert_equal(recieved_data[:ls][0][:env], options[:env])
    end

    logdna_thread.join
    server_thread.join
  end

  def test_all
    warn_method(2000)
    info_method(2001)
    fatal_method(2002)
    debug_method(2003)
    fatal_method_not_found(2004)
  end
end
