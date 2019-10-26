require 'socket'
class TestServer
  attr_accessor :a
  def startServer(port)
      server = TCPServer.new(port)
      puts server
      data = ''
      
      Thread.start(server.accept) { |client|    
      headers = {}
        while line = client.gets.split(' ', 2)
            break if line[0] == ""
            headers[line[0].chop] = line[1].strip
        end
        data = client.read(headers["Content-Length"].to_i)
        client.puts("HTTP/1.1 200 OK")
        client.close
      }.join
   
    return eval(data)
  end
  
  def startServerWithNotFound(port)
    server = TCPServer.new(port)
    
    count = 0 
    data = ''
    loop do
      count = count + 1
      Thread.start(server.accept) { |client|    
      headers = {}
        while line = client.gets.split(' ', 2)
            break if line[0] == ""
            headers[line[0].chop] = line[1].strip
        end
        data =+ client.read(headers["Content-Length"].to_i)
        if (count < 2) 
          client.puts("HTTP/1.1 404 Not Found")
        else
          client.puts("HTTP/1.1 200 OK")
        end
        client.close
      }.join  
      break if count == 2
    end
  return eval(data)
end
end


