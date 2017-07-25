require 'require_all'
require_all 'lib'

options = {
    :level => "INFO",    # LOG_LEVELS = ['TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'] or your customized log level
    :flushtime => 0.1,
    :env => 'PRODUCTION'
}

options2 = {
    :level => "INFO",    # LOG_LEVELS = ['TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'] or your customized log level
    :flushtime => 0.1,
    :env => 'STAGING'
}

options3 = {
    :level => "INFO",    # LOG_LEVELS = ['TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'] or your customized log level
    :flushtime => 0.1,
}

options4 = {
    :level => "INFO",    # LOG_LEVELS = ['TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'] or your customized log level
    :flushtime => 0.1,
}




logger = Logdna::Ruby.new('your-ingestion-key', options)
logger.log('1No metadata, production env')

logger = Logdna::Ruby.new('your-ingestion-key', options2)
logger.log('2With metadata, staging env', {:meta => {:once => {:first => "nested1", :another => "nested2"}}, :level => "TRACE"})

logger = Logdna::Ruby.new('your-ingestion-key', options3)
logger.log('3No metadata, development env changed to production env', {:level => "TRACE", :env => "PRODUCTION"})

logger = Logdna::Ruby.new('your-ingestion-key', options4)
logger.log('4No metadata, no env')



