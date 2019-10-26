require_relative "../lib/logdna.rb"
require_relative "../lib/logdna/client.rb"
require 'socket'

server = TCPServer.new("localhost", 3000)
client = server.accept

client.write("hello")










# RSpec.describe "" do
#   before do
#
#   end
#
#
#   # let(:uri) {}
#   let(:opts) {{:app => "app"}}
#   let (:options) {
#     {
#         :hostname => 'rubyTestHost',
#         :ip =>  '75.10.4.81',
#         :mac => '00:00:00:a1:2b:cc',
#         :app => 'rubyApplication',
#         :level => "INFO",
#         :env => "PRODUCTION",
#         :endpoint => "https://logs.logdna.com/logs/ingest",
#         :flush_interval => 1,
#         :flush_size => 1,
#         :retry_timeout => 60
#     }
#   }
#
#   it "" do
#     request = spy("l;;;;;;;")
#     response = double(Net::HTTP)
#
#     mockUri = double("uri")
#     allow(mockUri).to receive(:hostname).and_return("host")
#     allow(mockUri).to receive(:port).and_return("port")
#     allow(mockUri).to receive(:scheme)
#     allow(response).to receive(:start)
#
#     client = Logdna::Client.new(request, mockUri, options)
#     client.write_to_buffer("lllll", {})
#
#
#     expect(request).to receive(:body)
#   end
#
# end
