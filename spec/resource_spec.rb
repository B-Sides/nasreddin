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
           foo.bar.should == 'qux'
       end

       it "should be able to delete an object" do
           stub_remote_call_and_ensure do |arg|
               arg[:method].should == 'DELETE'
               arg[:params].should == {}
               arg[:id].should == 1
           end
           foo = Foo.new 'id' => 1, 'bar' => 'bar'
           foo.destroy
           foo.deleted?.should be_true
       end
   end
end
