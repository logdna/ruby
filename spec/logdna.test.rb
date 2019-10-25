require_relative "../lib/logdna.rb"
require_relative "../lib/logdna/client.rb"

RSpec.describe "should call the level named methods and assign the correct method" do
  before do
    allow(logger).to receive(:log)
  end
  let (:log_message) {"logging message"}
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
        :flush_size => 5,
        :retry_timeout => 60
    }
  }
  let (:logger) {Logdna::Ruby.new("PPPPPPP", options)}

  it "should call and assignt the level accordingly - debug" do
    logger.debug(log_message)
    expect(logger).to have_received(:log).with(log_message, {:level=>"DEBUG"})
  end
  it "should call and assignt the level accordingly - warn" do
    logger.warn(log_message)
    expect(logger).to have_received(:log).with(log_message, {:level=>"WARN"})
  end
  it "should call and assignt the level accordingly - info" do
    logger.info(log_message)
    expect(logger).to have_received(:log).with(log_message, {:level=>"INFO"})
  end
  it "should call and assignt the level accordingly - fatal" do
    logger.fatal(log_message)
    expect(logger).to have_received(:log).with(log_message, {:level=>"FATAL"})
  end
  it "should call and assignt the level accordingly - error" do
    logger.error(log_message)
    expect(logger).to have_received(:log).with(log_message, {:level=>"ERROR"})
  end
  it "should call and assignt the level accordingly - trace" do
    logger.trace(log_message)
    expect(logger).to have_received(:log).with(log_message, {:level=>"TRACE"})
  end
end
