require 'torquebox/messaging'
require 'multi_json'

module Nasreddin
  class Resource
    class<<self
      attr_accessor :resource

      def all
        remote_call({ method: 'GET' })
      end

      def find(*args)
        params = args.last.kind_of?(Hash) ? args.pop : {}
        id = args.shift

        remote_call({ method: 'GET', id: id, params: params })
      end

      def inherited(sub)
        sub.resource = @resource
      end

      private
      def queue
        @queue ||= TorqueBox::Messaging::Queue.new("/queues/#{@resource}")
      end

      def remote_call(params)
        status, _, data = *(queue.publish_and_receive(params, persistant: false))
        if status == 200
          resp = MultiJson.load(data)
          if resp.kind_of? Array
            resp.map { |r| new(r) }
          else
            new(resp)
          end
        else
          nil
        end
      end
    end

    def initialize(data)
      @data = data
    end

    def method_missing(mid, *args, &block)
      if @data.keys.include?(mid.to_s)
        @data[mid.to_s]
      else
        super
      end
    end

    def respond_to(mid)
      @data.keys.include?(mid.to_s) || super
    end
  end

  def self.Resource(name)
    ret = Class.new(Resource)
    ret.resource = name
    ret
  end
end
