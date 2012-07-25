require 'bundler/gem_tasks'
require 'yard'

desc 'Run tests & build the gem'
task :default => [:test, :build]

desc 'Run all the tests'
task :test do
  sh "bacon -a -I#{File.dirname(__FILE__)}/test"
end

YARD::Rake::YardocTask.new do |t|
  t.name = 'doc'
  t.files = Dir["#{File.dirname(__FILE__)}/lib/**/*"]
end
