require 'require_all'
require_all 'lib'


options = {hostname: "yondfsoikplghjniodhnfvreulwignfewfnrleuwinf"}


logger1 = Logdna::Ruby.new('Your ingestion key', options)

logger1.level = Logger::TRACE
logger1.log('is this trace')

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




