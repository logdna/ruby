module Resources
  LOG_LEVELS = ['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL', 'TRACE'].freeze
  DEFAULT_REQUEST_HEADER = { 'Content-Type' => 'application/json; charset=UTF-8' }.freeze
  DEFAULT_REQUEST_TIMEOUT = 180000
  MS_IN_A_DAY = 86400000
  MAX_REQUEST_TIMEOUT = 300000
  MAX_LINE_LENGTH = 32000
  MAX_INPUT_LENGTH = 80
  FLUSH_INTERVAL = 0.25
  TIMER_OUT = 15
  FLUSH_BYTE_LIMIT = 500000
  ENDPOINT = 'https://logs.logdna.com/logs/ingest'.freeze
  MAC_ADDR_CHECK = /^([0-9a-fA-F][0-9a-fA-F]:){5}([0-9a-fA-F][0-9a-fA-F])$/
  IP_ADDR_CHECK = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
end
