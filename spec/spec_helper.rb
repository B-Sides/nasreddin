#require 'torquespec'
#require 'torquebox-core'
require 'pry'
require 'nasreddin/resource'
require 'nasreddin/api-server'

RSpec.configure do |config|
 config.mock_with :mocha
end

class Foo < Nasreddin::Resource('foo')
end
