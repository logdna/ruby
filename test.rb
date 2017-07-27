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




logger = Logdna::Ruby.new('Your Ingestion Key', options);
logger.log('YOYO');
logger.log('EQWEJQWIOE');



