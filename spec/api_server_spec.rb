require 'spec_helper'

describe Nasreddin::APIServer do

  describe '#queryize' do
    it 'should handle being passed nil' do
      app_mock = mock('app')
      server = Nasreddin::APIServer.new(app_mock)
      lambda { server.send(:queryize, nil) }.should_not raise_error
    end
  end
end
