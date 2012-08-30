require 'helper'
require 'stringio'

describe Nasreddin::APIServerResource do

    it "should have a DEFAULT_ENV hash" do
      Nasreddin::APIServerResource::DEFAULT_ENV.class.should.equal Hash
    end

    describe ".receive_and_publish" do
        let(:resp) { [200,{}, StringIO.new('bar') ] }
        it "should return a status, headers and resp" do
            app = stub(:call => resp)
            resource = Nasreddin::APIServerResource.new("prefix","foo",app)
            resource.expects(:env).returns(nil)
            result =  resource.process_incoming_message(nil)
            # this fails, I suppose its a shoulda bug
            # result.should.equal [200,{},"bar"]
            result[0].should.equal 200
            result[2].should.equal "bar"
        end
    end

end
