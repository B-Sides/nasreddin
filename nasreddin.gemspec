# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'nasreddin/version'

Gem::Specification.new do |s|
  s.name        = 'nasreddin'
  s.version     = Nasreddin::VERSION
  s.authors     = ['Josh Ballanco']
  s.email       = ['jballanc@gmail.com']
  s.homepage    = ''
  s.summary     = %q| A library for making distributed calls via ZeroMQ |
  s.description = %q| Nasreddin is a library to make distributed calls via ZeroMQ |

  s.rubyforge_project = ''

  s.files         = Dir['./{bin,lib,test}/**/*']
  s.test_files    = Dir['./test/**/*']
  s.executables   = Dir['./bin/*']
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'zmq'
  s.add_development_dependency 'bacon'
end
