require "mocha-on-bacon"
require 'torquebox-core'
require 'nasreddin/resource.rb'
require 'nasreddin/remote_torquebox_adapter.rb'
require 'nasreddin/api-server'
require 'pry'


module BaconExtensions
    def let(name,&block)
       BaconExtensions.module_eval do
           define_method(name) do 
              @_memoized ||= {}
              @_memoized.fetch(name) { |k| @_memoized[k] = instance_eval(&block) }
           end
       end
    end
end

class Bacon::Context
    include BaconExtensions
end

class MockServer
  BASIC_APP = lambda do |env|
    [200, {"ContentType" => "text/plain"}, ["body"]]
  end

  def initialize(options, app = BASIC_APP)
    Rack::Builder.new do
      use Rack::Lint
      use Nasreddin::APIServer, options
      use Rack::Lint
      run app
    end.to_app
  end
end
