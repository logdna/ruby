require 'logdna'

describe "Client initialization" do
    it "no options provided should use the default settings" do
        opts = {
          :hostname=>"rubyTestHost",
          :ip=>"75.10.4.81",
          :mac=>"00:00:00:a1:2b:cc",
          :app=>"rubyApplication",
          :level=>"INFO",
          :env=>"PRODUCTION",
          :endpoint=>"https://logs.logdna.com/logs/ingest"
        }
        client = Logdna::Client.new('request', 'test.com', opts)
        puts client
        #client.uri.should == 'test.com'
    end
end
