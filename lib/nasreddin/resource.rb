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

      def create(properties = {})
        new(properties).save
      end

      def inherited(sub)
        sub.resource = @resource
      end

      def queue
        @queue ||= TorqueBox::Messaging::Queue.new("/queues/#{@resource}")
      end

      def remote_call(params)
        status, _, data = *(queue.publish_and_receive(params, persistant: false))
        if status == 200
          if params[:method] == 'GET'
            resp = MultiJson.load(data)
            if resp.kind_of? Array
              resp.map { |r| new(r) }
            else
              new(resp)
            end
          else
            true
          end
        else
          nil
        end
      end
    end

    def save
      if @data['id'].to_s.empty?
        self.class.remote_call({ method: 'PUT', params: @data })
      else
        self.class.remote_call({ method: 'POST', id: @data['id'], params: @data })
      end
    end

    def initialize(data)
      @data = data
      @data.each do |key, value|
        unless respond_to?("#{key.to_s}=")
          self.class.send(:define_method, "#{key.to_s}=") do |other|
            @data[key.to_s] = other
          end
        end
      end
    end

    def method_missing(mid, *args, &block)
      if @data.keys.include?(mid.to_s)
        @data[mid.to_s]
      else
        super
      end
    end

    def respond_to?(mid)
      @data.keys.include?(mid.to_s) || super
    end
  end

  def self.Resource(name)
    ret = Class.new(Resource)
    ret.resource = name
    ret
  end
end
