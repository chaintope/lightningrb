# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lightning/version'

Gem::Specification.new do |spec|
  spec.name          = 'lightning'
  spec.version       = Lightning::VERSION
  spec.authors       = ['Hajime Yamaguchi']
  spec.email         = ['gen.yamaguchi0@gmail.com']

  spec.summary       = 'A Ruby implementation of the Lightning Network'
  spec.description   = 'A Ruby implementation of the Lightning Network'
  spec.homepage      = 'https://github.com/Yamaguchi/lightningrb'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'pre-commit'
  spec.add_development_dependency 'protobuf'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-airbnb'

  spec.add_runtime_dependency 'algebrick'
  spec.add_runtime_dependency 'async-http'
  spec.add_runtime_dependency 'bitcoinrb'
  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.0'
  spec.add_runtime_dependency 'concurrent-ruby-edge'
  spec.add_runtime_dependency 'eventmachine'
  spec.add_runtime_dependency 'leveldb-ruby'
  spec.add_runtime_dependency 'lightning-invoice'
  spec.add_runtime_dependency 'lightning-onion'
  spec.add_runtime_dependency 'dijkstraruby'
  spec.add_runtime_dependency 'noise-ruby'
  spec.add_runtime_dependency 'rbnacl'
  spec.add_runtime_dependency 'sqlite3'
end
