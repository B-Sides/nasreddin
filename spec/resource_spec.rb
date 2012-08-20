require 'spec_helper'

describe Nasreddin::Resource do
  let(:foo) { stub_everything() }

  def stub_remote_call_and_ensure(&block)
    Foo.expects(:remote_call).with do |params|
        params.should be_an_instance_of(Hash)
        block.call(params)
    end.returns([200, foo])
  end

  describe "as consumer" do
    before do
      TorqueBox::Messaging::Queue.stubs(:new).returns(stub_everything())
    end

    it "should be able to search an object by :id" do
      stub_remote_call_and_ensure do |arg|
        arg[:method].should == 'GET'
        arg[:id].should == 1
      end

      Foo.find(1).should eq(foo)
    end

    it "should be able to search an object by params" do
      stub_remote_call_and_ensure do |arg|
        arg[:method].should == 'GET'
        arg[:params].should == { 'bar' => 'bar' }
        arg[:id].should be_nil
      end

      Foo.find('bar' => 'bar').should eq(foo)
    end

    it "should be able to create an object" do
      stub_remote_call_and_ensure do |arg|
        arg[:method].should == 'POST'
        arg[:params].should == { 'bar' => 'bar' }
        arg[:id].should be_nil
      end

      Foo.create( 'bar' => 'bar' )
    end

    it "should be able to update an object" do
      stub_remote_call_and_ensure do |arg|
        arg[:method].should == 'PUT'
        arg[:params].should == { 'bar' => 'qux', 'id' => 1 }
        arg[:id].should == 1
      end
      foo = Foo.new 'id' => 1, 'bar' => 'bar'
      foo.bar = 'qux'
      foo.save
    end

    it "should be able to delete an object" do
      stub_remote_call_and_ensure do |arg|
        arg[:method].should == 'DELETE'
        arg[:id].should == 1
      end
      foo = Foo.new 'id' => 1, 'bar' => 'bar'
      foo.destroy
      foo.deleted?.should be_true
    end
  end

  describe "#remote_call" do
    it "should publish on the queue" do
      queue = mock('queue')
      params = { method: 'GET' }
      queue.expects(:publish_and_receive).returns([200, nil, MultiJson.dump({'bar' => 'baz'})])
      Foo.stubs(:queue).returns(queue)
      Foo.remote_call(params)
    end
  end

  describe "#call_api" do
    let(:foo_params) { {'id' => 1, 'bar' => 'bar'} }
    let(:json_foo) { MultiJson.dump(foo_params) }

    it "is able to return an object" do
      queue = mock('queue')
      Foo.stubs(:queue).returns(queue)
      queue.expects(:publish_and_receive).returns([200, nil, json_foo])
      obj = Foo.call_api( :method => 'GET' )
      obj.should be_an_instance_of(Foo)
      obj.bar.should == 'bar'
      obj.id.should == 1
    end
  end

  describe ".call_api" do
    let(:foo_params){ {'id' => 1, 'bar' => 'bar'} }
    let(:updated_foo_params){ {'id' => 1, 'bar' => 'geez'} }
    let(:foo){ Foo.new(foo_params) }
    let(:updated_foo_params_json) { MultiJson.dump(updated_foo_params) }

    it "is able to update the object" do
      queue = mock('queue')
      Foo.stubs(:queue).returns(queue)
      queue.expects(:publish_and_receive).returns([200, nil, updated_foo_params_json])

      foo.call_api({ method: 'PUT', params: updated_foo_params })
      foo.bar.should == 'geez'
    end
  end
end
