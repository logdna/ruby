# frozen_string_literal: true

require "socket"

class TestServer
  def start_server(port)
    TCPServer.new(port)
  end

  def accept_logs_and_respond(server, res)
    data = ""
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

    eval(data)
  end
end
