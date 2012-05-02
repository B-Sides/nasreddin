require 'torquebox-core'
require 'torquebox-messaging'
require 'torquespec/torquespec'
require 'torquespec/server'
require 'rack/mock'

FIXTURES_PATH = File.expand_path('../fixtures/', __FILE__)

class Bacon::Context
  # Add :deploy method to Bacon
  include TorqueSpec
end


Thread.current[:app_server] = TorqueSpec::Server.new
Thread.current[:app_server].start(:wait => 120)

shared 'a test with deploys' do
  before do
    TorqueSpec.deploy_paths.each do |path|
      Thread.current[:app_server].deploy(path)
    end if TorqueSpec.respond_to?( :deploy_paths )
  end

  after do
    TorqueSpec.deploy_paths.each do |path|
      Thread.current[:app_server].undeploy(path)
    end if TorqueSpec.respond_to?( :deploy_paths )
  end
end

at_exit do
  Thread.current[:app_server].stop
end
