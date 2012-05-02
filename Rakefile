require 'bundler/gem_tasks'

desc 'Run tests & build the gem'
task :default => [:test, :build]

desc 'Run all the tests'
task :test do
  sh "bacon -a -I#{File.dirname(__FILE__)}/test"
end

