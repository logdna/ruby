# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
## [v1.5.0] - 2021-01-29
### Added
- `request_size` option to control the upper limit of a request.
- `retry_timeout` option to control the base timeout for retries.
- `retry_max_attempts` option to control maximum number of retries.
- `retry_max_jitter` option to control the maximum amount of jitter (random time added) for each tried request.

### Changed
- Set the minimum required ruby version to 2.5.0.

### Fixed
- The client sometimes blocking the main thread during requests.

## [v1.4.2] - 2020-03-13
### Fixed
- Schedule flusher blocks main thread.

## [v1.4.1] - 2020-03-19
### Fixed
- Missing level method causing invalid log level error.

## [v1.4.0] - 2020-01-30
### Added
- Everything.

[Unreleased]: https://github.com/logdna/ruby/compare/v1.5.0...master
[v1.5.0]: https://github.com/logdna/ruby/compare/v1.4.2...v1.5.0
[v1.4.2]: https://github.com/logdna/ruby/compare/v1.4.1...v1.4.2
[v1.4.1]: https://github.com/logdna/ruby/compare/v1.4.0...v1.4.1
[v1.4.0]: https://github.com/logdna/ruby/releases/tag/v1.4.0
