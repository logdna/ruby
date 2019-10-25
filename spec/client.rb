require_relative "../lib/logdna.rb"
require_relative "../lib/logdna/client.rb"
RSpec.describe "" do
  before do

  end


  let(:uri) {'uri'}
  let(:opts) {{:app => "app"}}
  let (:options) {
    {
        :hostname => 'rubyTestHost',
        :ip =>  '75.10.4.81',
        :mac => '00:00:00:a1:2b:cc',
        :app => 'rubyApplication',
        :level => "INFO",
        :env => "PRODUCTION",
        :endpoint => "https://logs.logdna.com/logs/ingest",
        :flush_interval => 1,
        :flush_size => 1,
        :retry_timeout => 60
    }
  }

  it "" do
    request = spy("l;;;;;;;")

  # allow(request).to receive(:body)
    # allow(request).to receive(:body)

    client = Logdna::Client.new(request, uri, options)
    client.write_to_buffer("lllll", {})


    expect(request).to receive(:body)
  end

end
