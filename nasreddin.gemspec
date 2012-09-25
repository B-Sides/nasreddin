# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'nasreddin/version'

Gem::Specification.new do |s|
  s.name        = 'nasreddin'
  s.version     = Nasreddin::VERSION
  s.authors     = ['Josh Ballanco']
  s.email       = ['jballanc@gmail.com']
  s.homepage    = ''
  s.summary     = %q| A library for making distributed calls via HornetQ |
  s.description = %q| Nasreddin is a library to make distributed calls via HornetQ |

  s.rubyforge_project = ''

  s.files         = Dir['./{lib,spec}/**/*']
  s.files        += ['README.md']
  s.test_files    = Dir['./spec/**/*']
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'torquebox', '~> 2.1.1'
  s.add_runtime_dependency 'rack', '~> 1.4.1'
  s.add_runtime_dependency 'multi_json', '~> 1.3.4'
  s.add_development_dependency 'rack-test', '~> 0.6.1'
  s.add_development_dependency 'torquebox-server', '~> 2.1.1'
  s.add_development_dependency 'kramdown', '~> 0.13.7'
  s.add_development_dependency 'yard', '~> 0.8.2'
  s.add_development_dependency 'bacon', '~> 1.1.0'
  s.add_development_dependency 'mocha-on-bacon'
end
