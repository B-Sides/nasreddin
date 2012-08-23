#require 'torquebox/messaging'
require 'multi_json'

module Nasreddin
  class RemoteTorqueboxAdapter

    def load_data(data,resource, as_objects = true)
      resp = MultiJson.load(data)
      resp = resp[@resource] if resp.keys.include?(@resource)
      if resp.kind_of? Array
        as_objects ? resp.map { |r| @klass.new(r) } : resp
      else
        as_objects ? @klass.new(resp) : resp
      end
    end

    def succeded?(status)
      status > 199 && status < 300
    end

    def queue
     @queue ||= TorqueBox::Messaging::Queue.new("/queues/#{@resource}")
    end

    def call(params, as_new_objects=false)
      status, _, data = *(queue.publish_and_receive(params, persistant: false))
      values = load_data(data,@resource,as_new_objects) if data && !data.empty?
      [ succeded?(status), values ]
    end

    def initialize(resource, klass)
      @resource = resource
      @klass = klass
    end
  end

end
