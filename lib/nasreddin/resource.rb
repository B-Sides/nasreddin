require 'torquebox/messaging'
require 'multi_json'

module Nasreddin
  # == Nasreddin Resource
  # Provides a base class for implementing an API backed data object.
  # A minimal implementation could be:
  #   class Car < Nasreddin::Resource('cars')
  #   end
  class Resource
    class<<self
      attr_accessor :resource

      # Allows fetching of all entities without requiring filtering
      # parameters.
      def all
        remote_call({ method: 'GET' })
      end

      # Allows searching for a specific entity or a collection of
      # entities that match a certain criteria.
      # example usage:
      #   Car.find(15)
      #   # => #<Car:0x5fafa486>
      #
      #   Car.find(model: 'Ford')
      #   # => [ #<Car:0x5fafa486> ]
      #
      #   Car.find(15, model: 'Ford')
      #   # => [ #<Car:0x5fafa486> ]
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

      private

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
    end

    def method_missing(mid, *args, &block)
      mid = mid.to_s
      if mid =~ /=$/
        prop = mid[0...-1]
        if @data.keys.include?(prop)
          @data[prop] = args.first
        else
          super
        end
      else
        if @data.keys.include?(mid.to_s)
          @data[mid.to_s]
        else
          super
        end
      end
    end

    def respond_to?(mid)
      if mid.to_s =~ /=$/
        @data.keys.include?(mid.to_s[0...-1]) || super
      else
        @data.keys.include?(mid.to_s) || super
      end
    end
  end

  def self.Resource(name)
    ret = Class.new(Resource)
    ret.resource = name
    ret
  end
end
