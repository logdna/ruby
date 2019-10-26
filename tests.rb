require_relative "lib/logdna.rb"
require_relative "lib/logdna/client.rb"
require_relative "test-server.rb"
require "minitest/autorun"
class TestFoo < Minitest::Test
     i_suck_and_my_tests_are_order_dependent! 

     def get_options(port)
      return {
        :hostname => 'rubyTestHost',
        :ip =>  '75.10.4.81',
        :mac => '00:00:00:a1:2b:cc',
        :app => 'rubyApplication',
        :level => "INFO",
        :env => "PRODUCTION",
        :endpoint => "http://localhost:#{port}",
        :flush_interval => 1,
        :flush_size => 5,
        :retry_timeout => 1
      }
     end
    
     @@log_line = "log line"
    
    def warn_method(port)
      options = get_options(port)
      logdnaThread = Thread.start do
        logger = Logdna::Ruby.new("pp", options)
        logger.warn(@@log_line)
      end
    
      serverThread = Thread.start do
        server = TestServer.new()
        recievedData = server.startServer(port)
            
        assert_equal(recievedData[:ls][0][:line], @@log_line)
        assert_equal(recievedData[:ls][0][:app], options[:app])
        assert_equal(recievedData[:ls][0][:level], "WARN")
        assert_equal(recievedData[:ls][0][:env], options[:env])
      end
      
      logdnaThread.join
      serverThread.join 
    end
    
    def info_method(port)
      options = get_options(port)
      logdnaThread = Thread.start do
        logger = Logdna::Ruby.new("pp", options)
        logger.info(@@log_line)
      end
       
      serverThread = Thread.start do
        sor = TestServer.new()
        recievedData = sor.startServer(port)
            
        assert_equal(recievedData[:ls][0][:line], @@log_line)
        assert_equal(recievedData[:ls][0][:app], options[:app])
        assert_equal(recievedData[:ls][0][:level], "INFO")
        assert_equal(recievedData[:ls][0][:env], options[:env])
      end
      
      logdnaThread.join
      serverThread.join
    end
    def debug_method(port)
      options = get_options(port)
      logdnaThread = Thread.start do
        logger = Logdna::Ruby.new("pp", options)
        logger.debug(@@log_line)
      end
       
      serverThread = Thread.start do
        sor = TestServer.new()
        recievedData = sor.startServer(port)
            
        assert_equal(recievedData[:ls][0][:line], @@log_line)
        assert_equal(recievedData[:ls][0][:app], options[:app])
        assert_equal(recievedData[:ls][0][:level], "DEBUG")
        assert_equal(recievedData[:ls][0][:env], options[:env])
      end
      
      logdnaThread.join
      serverThread.join
    end
    def fatal_method(port)
      options = get_options(port)
      logdnaThread = Thread.start do
        logger = Logdna::Ruby.new("pp", options)
        logger.fatal(@@log_line)
      end
       
      serverThread = Thread.start do
        sor = TestServer.new()
        recievedData = sor.startServer(port)
            
        assert_equal(recievedData[:ls][0][:line], @@log_line)
        assert_equal(recievedData[:ls][0][:app], options[:app])
        assert_equal(recievedData[:ls][0][:level], "FATAL")
        assert_equal(recievedData[:ls][0][:env], options[:env])
      end
      
      logdnaThread.join
      serverThread.join
    end
    
    # Should retry to connect and preserve the failed line
    def fatal_method_not_found(port)
      second_line = " second line"
      options = get_options(port)
      logdnaThread = Thread.start do
        logger = Logdna::Ruby.new("pp", options)
        logger.fatal(@@log_line)
        logger.fatal(second_line)
      end
       
      serverThread = Thread.start do
        sor = TestServer.new()
        data = ''
        recievedData = sor.startServerWithNotFound(port)
        # The order of recieved lines is unpredictable.
        recievedLines = [
          recievedData[:ls][0][:line], 
          recievedData[:ls][1][:line]
        ]
  
        assert_includes(recievedLines, @@log_line)
        assert_includes(recievedLines, second_line)
        
        assert_equal(recievedData[:ls][0][:app], options[:app])
        assert_equal(recievedData[:ls][0][:level], "FATAL")
        assert_equal(recievedData[:ls][0][:env], options[:env])
      end
      
      logdnaThread.join
      serverThread.join
    end
  
    def test_all
      warn_method(2000)
      info_method(2001)
      fatal_method(2002)
      debug_method(2003)
      fatal_method_not_found(2004)
    end
end

