require 'helper'

describe 'A TorqueBox::Messaging sanity test' do
  it 'should receive responses for servers' do
    foo = TorqueBox::Messaging::Queue.start('/queues/foo')
    t = Thread.new { loop { foo.receive_and_publish { |msg| msg.upcase } } }
    foo.publish_and_receive('hello').should.equal 'HELLO'
    t.kill
    foo.stop
  end
end
