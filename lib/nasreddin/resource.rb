require 'torquebox/messaging'
require 'multi_json'

module Nasreddin

  class SaveError < Exception ; end

  # == Nasreddin Resource
  # Provides a base class for implementing an API backed data object.
  # A minimal implementation could be:
  #   class Car < Nasreddin::Resource('cars')
  #   end
  class Resource
    class<<self
      attr_accessor :resource

      def subclasses; (@subclasses ||= []); end

      def inherited(sub)
        subclasses << sub
        sub.resource = @resource
      end

      # Allows fetching of all entities without requiring filtering
      # parameters.
      def all
        call_api({ method: 'GET' })
      end

      # Allows searching for a specific entity or a collection of
      # entities that match a certain criteria.
      # example usage:
      #   Car.find(15)
      #   # => #<Car:0x5fafa486>
      #
      #   Car.find(make: 'Ford')
      #   # => [ #<Car:0x5fafa486> ]
      #
      #   Car.find(15, make: 'Ford')
      #   # => [ #<Car:0x5fafa486> ]
      def find(*args)
        params = args.last.kind_of?(Hash) ? args.pop : {}
        id = args.shift

        call_api({ method: 'GET', id: id, params: params })
      end

      # Allows creating a new record in one shot
      # returns true if the record was created
      # example usage:
      #   Car.create make: 'Ford', model: 'Focus'
      #   # => true or false
      def create(properties = {})
        new(properties).save
      end

      # Allows destroying a resource without finding it
      # example usage:
      # Car.destroy(15)
      # # => true or false
      def destroy(id)
        !call_api({ method: 'DELETE', id: id }).nil?
      end

      def queue
        @queue ||= TorqueBox::Messaging::Queue.new("/queues/#{@resource}")
      end

      def load_data(data, as_objects)
        resp = MultiJson.load(data)
        resp = resp[@resource] if resp.keys.include?(@resource)
        if resp.kind_of? Array
          as_objects ? resp.map { |r| new(r) } : resp
        else
          as_objects ? new(resp) : resp
        end
      end

      def call_api(params)
        status, data = remote_call(params)
        case status
        when 200...300
          data
        else
          nil
        end
      end

      def remote_call(params, as_objects = true)
        status, _, data = *(queue.publish_and_receive(params, persistant: false))
        [ status, load_data(data, as_objects) ]
      end
    end

    # Custom to_json implementation
    # passes through options
    def to_json(options={})
      @data.to_json(options)
    end

    # Calls the remote api
    # Loads any data provided into the instance
    # returns true if the status was in the 200 range
    def call_api(params)
      status, values = self.class.remote_call(params, false)
      @data = values if values && !values.empty?
      (200...300) === status
    end

    # Checks if the current instance has
    # already been deleted
    def deleted?
      @deleted
    end

    # Saves the current resource instance
    # if the instance has an ID it sends a PUT request
    # otherwise it sends a POST request
    # will raise an error if the object has been deleted
    # example usage:
    #   car = Car.find(15)
    #   car.miles += 1500
    #   car.save
    #   # => true or false
    def save
      raise SaveError.new("Cannot save a deleted resource") if deleted?

      if @data['id'].to_s.empty?
        call_api({ method: 'POST', params: @data })
      else
        call_api({ method: 'PUT', id: @data['id'], params: @data })
      end
    end

    # Destroys the current resource instance
    # example usage:
    # car = Car.find(15)
    # car.destroy
    # # => true or false
    def destroy
      if !@deleted
        @deleted = call_api({ method: 'DELETE', id: @data['id'] })
      end
    end

    # Initialize a new instance
    # also defines setters for any values given
    # example usage:
    #   car = Car.new make: 'Ford', model: 'Mustang'
    #   car.respond_to? :make=
    #   # => true
    def initialize(data={})
      @deleted = false
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

    def respond_to?(mid, include_private=false)
      @data.keys.include?(mid.to_s) || super
    end
  end

  def self.Resource(name)
    klass = Resource.subclasses.find { |k| k.resource == name }
    unless klass
      klass = Class.new(Resource)
      klass.resource = name
    end
    klass
  end
end
