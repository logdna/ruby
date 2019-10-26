# frozen_string_literal: true

require "socket"
class TestServer
  attr_accessor :a
  def start_server(port)
    server = TCPServer.new(port)
    puts server
    data = ""

    Thread.start(server.accept) { |client|
      headers = {}
      while line = client.gets.split(" ", 2)
        break if line[0] == ""

        headers[line[0].chop] = line[1].strip
      end
      data = client.read(headers["Content-Length"].to_i)
      client.puts("HTTP/1.1 200 OK")
      client.close
    }.join

    eval(data)
  end

  def return_not_found_res(port)
    server = TCPServer.new(port)

    count = 0
    data = ""
    loop do
      count += 1
      Thread.start(server.accept) { |client|
        headers = {}
        while line = client.gets.split(" ", 2)
          break if line[0] == ""

          headers[line[0].chop] = line[1].strip
        end
        data = + client.read(headers["Content-Length"].to_i)
        if count < 2
          client.puts("HTTP/1.1 404 Not Found")
        else
          client.puts("HTTP/1.1 200 OK")
        end
        client.close
      }.join
      break if count == 2
    end
    eval(data)
end
end
