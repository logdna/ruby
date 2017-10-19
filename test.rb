require 'require_all'
require_all 'lib'


options = {hostname: "new_ruby", meta:{:once => {:first => "nested1", :another => "nested2"}}}


logger1 = Logdna::Ruby.new('Your API KEY', options)

logger1.log('This is the start of test')
logger1.env = 'STAGING'
logger1.app = 'HELLO'
logger1.warn('Warn message with Staging and Hello')
logger1.clear
logger1.log('Is everything back to normal?')


logger1.log('Testing env app name change using log')
logger1.env = 'PRODUCTION'
logger1.app = 'CHANGED'
logger1.log('This should be stage = PRODUCTION and appname = CHANGED')
logger1.log('Testing env app name change using other messages')


logger1.error('This is error message with env = DEVELOPMENT and appname = NIHAO', {:env => 'DEVELOPMENT', :app => 'NIHAO'})
logger1.log('Should not stay as DEVELOPMENT and NIHAO')
logger1.env = 'DEVELOPMENT'
logger1.app = 'NIHAO'
logger1.log('Now should be DEVELOPMENT and NIHAO')
logger1.log('Logging metadata in trace level', {:meta => {:once => {:first => "nested1", :another => "nested2"}}, :level => "TRACE"})


logger1.level = Logger::DEBUG
logger1.log('This is debug message')
logger1.add('this should not be supported')
logger1.fatal('Does this continue as fatal?')
logger1.log('This should be debug')


=begin
logger1.level = Logger::WARN
logger1.log('This should be warn')
logger1.trace('This should be trace')
logger1.log('Again warn level')

logger1.log('Warn level log1')
logger1.info('Info level log1')
logger1.level = Logger::DEBUG
logger1.log('DEBUG log1')

logger1.app = 'NEW APP NAME'
logger1.env = 'Staging'
logger1.level = 'INFO'



logger1.level = 'INFO'
logger1.level == Logger::INFO


logger1.log('are changes all updated')
=end
sleep 3




