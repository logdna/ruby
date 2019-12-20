# frozen_string_literal: true

module Resources
  LOG_LEVELS = %w[DEBUG INFO WARN ERROR FATAL TRACE]
  DEFAULT_REQUEST_HEADER = { "Content-Type" => "application/json; charset=UTF-8" }
  DEFAULT_REQUEST_TIMEOUT = 180_000
  MS_IN_A_DAY = 86_400_000
  MAX_REQUEST_TIMEOUT = 300_000
  MAX_LINE_LENGTH = 32_000
  MAX_INPUT_LENGTH = 80
  RETRY_TIMEOUT = 60
  FLUSH_INTERVAL = 0.25
  FLUSH_BYTE_LIMIT = 500_000
  ENDPOINT = "https://logs.logdna.com/logs/ingest"
  MAC_ADDR_CHECK = /^([0-9a-fA-F][0-9a-fA-F]:){5}([0-9a-fA-F][0-9a-fA-F])$/
  IP_ADDR_CHECK = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
end
