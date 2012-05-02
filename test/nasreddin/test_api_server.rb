require 'helper'
require 'nasreddin/api_server'

describe Nasreddin::APIServer do
  app_with_queues = <<-DD_END.gsub(/^ {4}/, '')
    ruby:
      version: '1.9'

    queues:
      /queues/foo:
  DD_END

  behaves_like 'a test with deploys'

  it 'can be used as a Rack compliant middleware' do
    app = Rack::Builder.new do
            use Rack::Lint
            use Nasreddin::APIServer
            use Rack::Lint
            run lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
          end
    Rack::MockRequest.new(app).get('/').body.should.equal 'OK'
  end

  it 'can be used to send Rack requests via HornetQ' do
    deploy(app_with_queues)
    app = Rack::Builder.new do
      use Rack::Lint
      use Nasreddin::APIServer, resources: 'foos'
      use Rack::Lint
      run lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
    end

    apiq = TorqueBox::Messaging::Queue.new('/queues/foo')
    p apiq.class
    apiq.publish_and_receive('GET /').should.equal 'OK'
  end
end
