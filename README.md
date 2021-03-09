
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-4-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->
<p align="center">
  <a href="https://app.logdna.com">
    <img height="95" width="201" src="https://raw.githubusercontent.com/logdna/artwork/master/logo%2Bruby.png">
  </a>
  <p align="center">Ruby gem for logging to <a href="https://app.logdna.com">LogDNA</a></p>
</p>

---

* **[Installation](#installation)**
* **[Quick Setup](#quick-setup)**
* **[API](#api)**
* **[Contributing](#contributing)**
* **[License](#license)**

# Installation

Add this line to your application's Gemfile:

```ruby
gem 'logdna'
```

And then execute:

    $ bundle

Or install it yourself as:

```bash
$ gem install logdna
```



# Quick Setup

After installation, call

```ruby
logger = Logdna::Ruby.new(your_api_key, options)
#<Logdna::Ruby:0x00000000000000>
```

to set up the logger.

Options are optional variables that may contain hostname, app name, mac address, ip address, log level specified.

```ruby
options = {
    :hostname => myHostName,
    :ip =>  myIpAddress,
    :mac => myMacAddress,
    :app => myAppName,
    :level => "INFO",    # LOG_LEVELS = ['TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'] or your customized log level (custom levels for Rails have to be sent with a log message)
    :env => "PRODUCTION",
    :meta => {:once => {:first => "nested1", :another => "nested2"}},
    :endpoint => "https://fqdn/logs/ingest"
}
```

To send logs, use "log" method. Default log level is "INFO"

```ruby
logger.log('This is my first log')
=> "Saved"  # Saved to buffer. Ready to be flushed automatically
```

Optionally you can use a block to do so

```ruby
logger.log { 'This is my second log' }
=> "Saved"
```

Log a message with particular metadata, level, appname, environment (one-time)

```ruby
logger.log('This is warn message', {:meta => {:meta => "data"}, :level => "WARN", :app => "awesome", :env => "DEVELOPMENT"})
```

Log a message with lasting metadata, level, appname, environment (lasting)

```ruby
logger.meta = {:once => {:first => "nested1", :another => "nested2"}}
logger.level = 'FATAL'  or  logger.level = Logger::FATAL
logger.app = 'NEW APP NAME'
logger.env = 'PRODUCTION'
logger.log('This messages and messages afterwards all have the above values')
```

Clear current metadata, level, appname, environment

```ruby
logger.clear
```

Check current log level:
    logger.info? => true
    logger.warn? => false

Log a message with a particular level easily

```ruby
logger.warn('This is a warning message')
logger.fatal('This is a fatal message')
logger.debug { 'This is a debug message' }
```

Hostname and app name cannot be more than 80 characters.

### Rails Setup

In your `config/environments/environment.rb`:

```ruby
Rails.application.configure do
  config.logger = Logdna::Ruby.new(your_api_key, options)
end
```

# Important Notes

1. This logger assumes that you pass in json formatted data
2. This logger is a singleton (do not create mutiple instances of the logger) even though the singleton structure is not strongly enforced.

# API

## Logdna::Ruby.new(ingestion_key, options = {})

Instantiates a new instance of the class it is called on. ingestion_key is required.

| Options | Default |
|---------|---------|
|{ :hostname => Host name } | Device's default hostname |
|{ :mac => MAC address } | Nil |
|{ :ip => IP address } | Nil |
|{ :app => App name } | 'default' |
|{ :level => Log level } | 'INFO' |
|{ :env => STAGING, PRODUCTION .. etc} | Nil |
|{ :meta => metadata} | Nil |
|{ :endpoint => LogDNA Ingestion URI | 'https://logs.logdna.com/logs/ingest' |
|{ :flush_interval => Limit to trigger a flush in seconds } | 0.25 seconds |
|{ :flush_size => Limit to trigger a flush in bytes } | 2097152 bytes = 2 MiB |
|{ :request_size => Upper limit of request in bytes } | 2097152 bytes = 2 MiB |
|{ :retry_timeout => Base timeout for retries in seconds } | 0.25 seconds |
|{ :retry_max_attempts => Maximum number of retries per request } | 3 attempts |
|{ :retry_max_jitter => Maximum amount of jitter to add to each retry request in seconds } | 0.25 seconds |

Different log level displays log messages in different colors as well.
- ![TRACE DEBUG INFO Colors](https://placehold.it/15/515151/000000?text=+)   "Trace"  "Debug"  "Info"
- ![WARN Color](https://placehold.it/15/ec9563/000000?text=+)   "Warn"
- ![ERROR Fatal Colors](https://placehold.it/15/e37e7d/000000?text=+)   "Error"  "Fatal"



# Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/logdna/ruby.


# License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/smusali"><img src="https://avatars.githubusercontent.com/u/34287490?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Samir Musali</b></sub></a><br /><a href="https://github.com/logdna/ruby/commits?author=smusali" title="Code">💻</a> <a href="https://github.com/logdna/ruby/commits?author=smusali" title="Documentation">📖</a> <a href="#maintenance-smusali" title="Maintenance">🚧</a></td>
    <td align="center"><a href="https://github.com/jakedipity"><img src="https://avatars.githubusercontent.com/u/29671917?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Jacob Hull</b></sub></a><br /><a href="https://github.com/logdna/ruby/commits?author=jakedipity" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/MattChoi1"><img src="https://avatars.githubusercontent.com/u/19616902?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Gun Woo choi</b></sub></a><br /><a href="https://github.com/logdna/ruby/commits?author=MattChoi1" title="Code">💻</a> <a href="https://github.com/logdna/ruby/commits?author=MattChoi1" title="Documentation">📖</a></td>
    <td align="center"><a href="https://github.com/vilyapilya"><img src="https://avatars.githubusercontent.com/u/17367511?v=4?s=100" width="100px;" alt=""/><br /><sub><b>vilyapilya</b></sub></a><br /><a href="https://github.com/logdna/ruby/commits?author=vilyapilya" title="Code">💻</a> <a href="https://github.com/logdna/ruby/commits?author=vilyapilya" title="Documentation">📖</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
