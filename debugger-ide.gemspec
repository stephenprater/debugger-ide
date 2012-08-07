# -*- encoding: utf-8 -*-
require File.expand_path('../lib/debugger-ide/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["A.G. Russell Knives"]
  gem.email         = ["stephenp@agrussell.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "debugger-ide"
  gem.require_paths = ["lib"]
  gem.version       = Debugger::IDE::VERSION

  gem.add_dependency 'slop'
  gem.add_dependency 'debugger'
  gem.add_dependency 'activesupport'
  gem.add_dependency 'builder'
  gem.add_dependency 'andand'

  gem.add_development_dependency 'pry'
end
