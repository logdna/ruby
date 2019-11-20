# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "logdna/version"

Gem::Specification.new do |spec|
  spec.name          = "logdna"
  spec.version       = LogDNA::VERSION
<<<<<<< HEAD
  spec.authors       = 'Gun Woo Choi, Derek Zhou, Vilya Levitskiy, Muaz Siddiqui'
  spec.email         = 'support@logdna.com'
  spec.summary       = 'LogDNA Ruby logger'
  spec.homepage      = 'https://github.com/logdna/ruby'
  spec.license       = 'MIT'
  spec.files         = Dir.glob("{lib}/**/*.rb") + %w(LICENSE README.md)
  spec.bindir        = 'exe'
=======
  spec.authors       = "Gun Woo Choi, Derek Zhou"
  spec.email         = "support@logdna.com"

  spec.summary       = "LogDNA Ruby logger"
  spec.homepage      = "https://github.com/logdna/ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
>>>>>>> rubocop and refacyor the test server
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

<<<<<<< HEAD
  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.0'
  spec.add_runtime_dependency 'require_all', '~> 1.4'
  spec.add_runtime_dependency 'json', '~> 2.0'
  spec.add_development_dependency 'rubocop', '~> 0.78'
=======
  spec.add_runtime_dependency "concurrent-ruby", "~> 1.0"
  spec.add_runtime_dependency "json", "~> 2.0"
  spec.add_runtime_dependency "require_all", "~> 1.4"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.5"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "webmock", "~> 2.3"
>>>>>>> rubocop and refacyor the test server
end
