require 'helper'

def stub_remote_call_and_ensure(el,ret=@foo,&block)
    el.expects(:remote_call).with do |params|
        params.class.should.equal Hash
        block.call(params)
    end.returns(ret)
end

describe Nasreddin::Resource do

    before do
      class Foo < Nasreddin::Resource('foo'); end
      @foo = mock()
    end

    it "should pass through .to_json to @data" do
      mock_data = mock()
      foo = Foo.new
      # implementation detail
      foo.instance_variable_set(:@data, mock_data)

      mock_data.expects(:to_json).with({})
      foo.to_json()
    end

    it "should pass through .as_json to @data" do
      mock_data = mock()
      foo = Foo.new
      # implementation detail
      foo.instance_variable_set(:@data, mock_data)

      mock_data.expects(:as_json).with({})
      foo.as_json()
    end

    it "should be able to search an object by :id" do
         stub_remote_call_and_ensure(Foo) do |arg|
            arg[:method].should == 'GET'
            arg[:id].should == 1
         end
        Foo.find(1).should.equal @foo
    end

    it "should be able to search an object by params" do
     stub_remote_call_and_ensure(Foo) do |arg|
        arg[:method].should == 'GET'
        arg[:params].should == { 'bar' => 'bar' }
        arg[:id].should.equal nil
     end

     Foo.find('bar' => 'bar').should.equal @foo
    end

    it "should be able to create an object" do
       Foo.remote.expects(:call).with do |arg|
           arg.class.should.equal Hash
           arg[:method].should == 'POST'
           arg[:params].should == { 'bar' => 'bar' }
           arg[:id].should.equal  nil
       end.returns([true,{ 'bar' => 'bar' }])

       Foo.create( 'bar' => 'bar' ).should.equal true
    end

    it "should be able to update an object" do
       foo = Foo.new 'id' => 1, 'bar' => 'bar'

       stub_remote_call_and_ensure(foo) do |arg|
           arg[:method].should == 'PUT'
           arg[:params].should == { 'bar' => 'qux', 'id' => 1 }
           arg[:id].should == 1
       end
       foo.bar = 'qux'
       foo.save
       foo.bar.should.equal 'qux'
    end

    it "should be able to delete an object" do
       foo = Foo.new 'id' => 1, 'bar' => 'bar'
       stub_remote_call_and_ensure(foo, true) do |arg|
           arg[:method].should == 'DELETE'
           arg[:id].should == 1
       end
       foo.destroy
       foo.deleted?.should.equal true
    end

    it "should be able to destroy an object by :id" do
      @foo.expects(:empty?).returns(true)
      stub_remote_call_and_ensure(Foo) do |arg|
        arg[:method].should == 'DELETE'
        arg[:id].should.equal 1
      end

      Foo.destroy(1).should.equal true
    end
end
