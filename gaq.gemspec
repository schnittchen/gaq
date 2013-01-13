# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gaq/version'

Gem::Specification.new do |gem|
  gem.name          = "gaq"
  gem.version       = Gaq::VERSION
  gem.authors       = ["Thomas Stratmann"]
  gem.email         = ["thomas.stratmann@9elements.com"]
  gem.description   = %q{Gaq is a lightweight gem for support of pushing static and dynamic data to the _gaq from the backend.}
  gem.summary       = %q{Renders _gaq initialization and the ga.js snippet. Supports pushing from the back end}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'actionpack'
  gem.add_development_dependency 'activesupport'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'terminal-notifier-guard'
  gem.add_development_dependency 'rb-fsevent' # used by guard for watching
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'debugger'
end
