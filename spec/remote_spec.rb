require 'spec_helper'

describe Nasreddin::RemoteTorqueboxAdapter do

   before do
     TorqueBox::Messaging::Queue.stubs(:new).returns(stub_everything())
   end

   describe "#remote_call" do
     let(:foo_params){ {'id' => 1, 'bar' => 'bar'} }
     let(:json_foo){ MultiJson.dump(foo_params) }

     it "is able to return an object" do
        queue = mock()
        queue.expects(:publish_and_receive).returns( [200,nil,json_foo] )
        Foo.remote.stubs(:queue).returns(queue)
        obj = Foo.remote.call( {:method => 'GET'}, true )
        obj.should be_an_instance_of(Foo)
        obj.bar.should == 'bar'
        obj.id.should == 1
     end
   end


   describe ".remote_call" do
    let(:foo_params){ {'id' => 1, 'bar' => 'bar'} }
    let(:updated_foo_params){ {'id' => 1, 'bar' => 'geez'} }
    let(:foo){ Foo.new(foo_params) }
    let(:updated_foo_params_json) { MultiJson.dump(updated_foo_params) }

    it "is able to update the object" do
        queue = mock()
        queue.expects(:publish_and_receive).returns( [200,nil,updated_foo_params_json] )
        Foo.remote.stubs(:queue).returns(queue)
        hash = foo.remote.call(updated_foo_params)
        hash['bar'].should == 'geez'
    end
   end
end
