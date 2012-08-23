require "helper"

describe Nasreddin::RemoteTorqueboxAdapter do
    before do
        class Foo < Nasreddin::Resource('foo'); end
        @remote = Nasreddin::RemoteTorqueboxAdapter.new('foo', Foo)
    end

    it "should know resource and klass" do
        @remote.resource.should.equal 'foo'
        @remote.klass.should.equal Foo
    end

    it "should start a new queue" do
        TorqueBox::Messaging::Queue.expects(:new).once.returns(true)
        @remote.queue.should.equal true
        @remote.queue.should.equal true
    end

    it "should send .publish_and_receive to Torquebox and return a Hash" do
        stubbed_torquebox = stub
        obj = {foo: 'bar'}
        serialized_obj = MultiJson.dump(obj)
        TorqueBox::Messaging::Queue.expects(:new).returns(stubbed_torquebox)
        stubbed_torquebox.expects(:publish_and_receive).with({},persistant:false).returns([200,nil,serialized_obj])
        status,values = @remote.call({})
        status.should.equal true
        values.should.equal 'bar'
    end
    
    describe "should send .publish_and_receive" do

        before do
            @stubbed_torquebox = stub
            @obj = {foo: {'bar' => 'geez'}}
            @serialized_obj = MultiJson.dump(@obj)
            TorqueBox::Messaging::Queue.expects(:new).returns(@stubbed_torquebox)
            @stubbed_torquebox.expects(:publish_and_receive).with({},persistant:false).returns([200,nil,@serialized_obj])

        end
        it "and return a new Object" do
            status,values = @remote.call({},true)
            status.should.equal true
            values.bar.should.equal 'geez'
        end
        it "and return a Hash" do
            status,values = @remote.call({})
            status.should.equal true
            values.should.equal({ 'bar' => 'geez'})
        end

    end

    it "should consider succeded for statuses from 200 to 299" do
        @remote.succeded?(200).should.equal true
        @remote.succeded?(240).should.equal true
        @remote.succeded?(299).should.equal true
    end

end
