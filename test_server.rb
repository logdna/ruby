# frozen_string_literal: true

require "socket"

class TestServer
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

  def accept_logs_and_respond(server, data, res)
    Thread.start(server.accept) { |client|
      headers = {}
      while line = client.gets.split(" ", 2)
        break if line[0] == ""

        headers[line[0].chop] = line[1].strip
      end
      data += client.read(headers["Content-Length"].to_i)
      client.puts(res)
      client.close
    }.join

    data
  end

  def return_not_found_res(port)
    server = TCPServer.new(port)
    data = ""
    accept_logs_and_respond(server, data, "HTTP/1.1 404 Not Found")
    data += accept_logs_and_respond(server, data, "HTTP/1.1 200 OK")

    eval(data)
  end
end
