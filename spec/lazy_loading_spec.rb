require 'spec_helper'

describe 'Lazy Loading wat' do
  before do
    resource = (0...8).map{65.+(rand(25)).chr}.join.downcase
    @remote = Nasreddin::RemoteTorqueboxAdapter.new(resource, Class)
    @queue = @remote.queue
  end
  it 'should not blow up because queue doesnt exist' do
    params = {}
    lambda { @queue.publish_and_receive(params, persistant: false) }.should_not raise_error(NativeException)
  end
end