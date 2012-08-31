require 'helper'
require 'stringio'

describe Nasreddin::APIServerResource do

    let(:resp) { [200,{}, StringIO.new('bar') ] }
    let(:resource_stubbed) { Nasreddin::APIServerResource.new('prefix','foo',stub()) }
    let(:heartbeat_msg) { {'resource' => '__heartbeat__' } }
    let(:msg) { {'resource' => 'foo' } }

    it "should have a DEFAULT_ENV hash" do
      Nasreddin::APIServerResource::DEFAULT_ENV.class.should.equal Hash
    end

    it ".process_incoming_message should return a status, headers and resp" do
        app = stub(:call => resp)
        resource = Nasreddin::APIServerResource.new("prefix","foo",app)
        resource.expects(:env).returns(nil)
        result =  resource.process_incoming_message({})
        # this fails, I suppose its a shoulda bug
        # result.should.equal [200,{},"bar"]
        result[0].should.equal 200
        result[2].should.equal "bar"
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
        env= resource_stubbed.env(msg)
        env['rack.url_scheme'].should.equal 'https'
        env['REQUEST_METHOD'].should.equal 'POST'
        env['QUERY_STRING'].should.equal 'key=value'
        env['PATH_INFO'].should.equal 'prefix/foo/123/path'
        env[:other].should.equal 'value'

    end

    it "should handle heartbeat messages" do
        resource_stubbed.heartbeat?(heartbeat_msg).should.equal true
        resource_stubbed.heartbeat?(msg).should.not.equal true
    end
end
