require 'spec_helper'

describe Nasreddin::Resource do

   let(:foo) { stub(:foo) }


   def stub_remote_call_and_ensure(&block)
      Foo.expects(:remote_call).with do |*args|
          a=args.pop
          a.should be_an_instance_of(Hash)
          block.call(a)
      end.returns(foo) 
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
            arg[:params].should == { 'foo' => 'bar' }
            arg[:id].should be_nil
         end

         Foo.find('foo' => 'bar').should eq(foo)
       end

       it "should be able to create an object" do
           stub_remote_call_and_ensure do |arg|
               arg[:method].should == 'POST'
               arg[:params].should == { 'foo' => 'bar' }
               arg[:id].should be_nil
           end

           Foo.create( 'foo' => 'bar' )
       end

       it "should be able to update an object" do
           stub_remote_call_and_ensure do |arg|
               arg[:method].should == 'PUT'
               arg[:params].should == { 'foo' => 'qux', 'id' => 1 }
               arg[:id].should == 1
           end
           foo = Foo.new 'id' => 1, 'foo' => 'bar'
           foo.foo = 'qux'
           foo.save

       end

       it "should be able to delete an object" do
           stub_remote_call_and_ensure do |arg|
               arg[:method].should == 'DELETE'
               arg[:params].should be_nil
               arg[:id].should == 1
           end
           foo = Foo.new 'id' => 1, 'foo' => 'bar'
           foo.destroy
           foo.deleted?.should be_true
       end
   end

   describe "#remote_call" do
     let(:foo_params){ {'id' => 1, 'foo' => 'bar'} }
     let(:json_foo){ MultiJson.dump(foo_params) }

     it "is able to return an object" do
        queue = mock()
        queue.expects(:publish_and_receive).returns( [200,nil,json_foo] )
        Foo.stubs(:queue).returns(queue)
        obj = Foo.remote_call( :method => 'GET' )
        obj['foo'].should == 'bar'
        obj['id'].should == 1
     end
   end


   describe ".remote_call" do
    let(:foo_params){ {'id' => 1, 'foo' => 'bar'} }
    let(:updated_foo_params){ {'id' => 1, 'foo' => 'geez'} }
    let(:foo){ Foo.new(foo_params) }
    let(:updated_foo_params_json) { MultiJson.dump(updated_foo_params) }

    it "is able to update the object" do
        queue = mock()
        queue.expects(:publish_and_receive).returns( [200,nil,updated_foo_params_json] )
        Foo.stubs(:queue).returns(queue)
        foo.remote_call(updated_foo_params)
        foo.foo.should == 'geez'
    end
   end
end
