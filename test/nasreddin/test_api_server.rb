require 'helper'
require 'stringio'

describe Nasreddin::APIServerResource do

    let(:resp) { [200,{}, StringIO.new('bar') ] }
    let(:resource_stubbed) { Nasreddin::APIServerResource.new('prefix','foo',stub()) }
    let(:heartbeat_msg) { {:params => {'__heartbeat__' => true } } }
    let(:msg) { {'resource' => 'foo' } }

    it "should have a DEFAULT_ENV hash" do
      Nasreddin::APIServerResource::DEFAULT_ENV.class.should.equal Hash
    end

    it ".process_incoming_message should return a status, headers and resp" do
        app = stub(:call => resp)
        resource = Nasreddin::APIServerResource.new("prefix","foo",app)
        resource.expects(:env).returns(nil)
        result =  resource.process_incoming_message({})
        result.should.equal [200,{},"bar"]
    end

    it "should connect to hornetq only once" do
        TorqueBox::Messaging::Queue.expects(:start).once.returns(stub())
        2.times { resource_stubbed.queue }
    end

    it "build an env Hash" do
        msg= {
            secure: true,
            method: 'post',
            params:  { key: 'value'},
            id: 123,
            path: 'path',
            other: 'value'
        }
        env = resource_stubbed.env(msg)
        env['rack.url_scheme'].should.equal 'https'
        env['REQUEST_METHOD'].should.equal 'POST'
        env['QUERY_STRING'].should.equal 'key=value'
        env['REQUEST_URI'].should.equal '/prefix/foo/123/path'
        env['other'].should.equal 'value'

    end

    it "should handle heartbeat messages" do
        resource_stubbed.is_heartbeat?(heartbeat_msg).should.equal true
        resource_stubbed.is_heartbeat?(msg).should.not.equal true
    end
end

describe "its a rack application" do
  extend Rack::Test::Methods
  let(:resp) { [200,{}, StringIO.new('bar') ] }

  def app
    TorqueBox::Messaging::Queue.expects(:start).once.returns(stub(:receive_and_publish => resp))
    MockServer.new  resources: %w| foo |
  end

  it "is working" do
    get '/'
    last_response.should.be.ok
    last_response.body.should.equal 'body'
  end
end
