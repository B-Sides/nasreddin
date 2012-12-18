require 'stringio'
require 'uri'

module Nasreddin

  class APIServer

    def initialize(app, options = {})
      @app = app
      @threads = {}
      @resources = options[:resources]
      @route_prefix = options[:route_prefix]
      if @resources
        @resources.each do |resource|
          @threads[resource] = Thread.new { Nasreddin::APIServerResource.new(@route_prefix,resource,@app).run }
        end
      else
        $stderr.puts "WARNING: Nasreddin::APIServer is being used without any resources specified!"
      end
    end

    def call(env)
      params = Rack::Request.new(env).params

      if is_heartbeat?(params)
          res = params['resource'] = params['resources'].pop
          params["resources.#{res}"] = @resources
          Nasreddin::Resource(@resource).remote_call(params)
      else
        @app.call(env)
      end
    end

    def is_heartbeat?(params)
      params.has_key? '__hearbeat__'
    end
  end

  class APIServerResource 

    DEFAULT_ENV = {
        'rack.errors'       => $stderr,
        'rack.input'        => StringIO.new,
        'rack.version'      => [1, 1],
        'rack.multithread'  => true,
        'rack.multiprocess' => true,
        'rack.run_once'     => false,
        'HTTP_ACCEPT'       => 'application/json',
        'HTTP_USER_AGENT'   => 'NasreddinAPI'
    }

    def initialize(route_prefix,resource,app)
      @resource = resource
      @route_prefix = route_prefix
      @app = app
    end

    def queue
      @queue ||= TorqueBox::Messaging::Queue.start("/queues/#{@resource}", durable: false)
    end

    def run
      begin
        loop do 
           queue.receive_and_publish &method(:process_incoming_message)
        end
      ensure
        queue.stop
      end
    end

    def is_heartbeat?(msg)
        msg[:params] && msg[:params].has_key?('__heartbeat__')
    end

    def call(env)
        @app.call(env)
    end

    def process_incoming_message(msg)
        return heartbeat_ok  if is_heartbeat?(msg)

        begin
          status, headers, body = call(env(msg))

          resp = ''
          body.each { |d| resp += d.to_s }
          body.close if body.respond_to?(:close)

        rescue Exception => err
          resp = "#{err.message}\n\n#{err.backtrace.join("\n")}"
        end

        [status, headers, resp]
    end

    def heartbeat_ok
        [200, nil, "OK"]
    end

    def env(msg)
      env = DEFAULT_ENV.clone
      env['rack.url_scheme'] = (msg.delete(:secure) ? 'https' : 'http')
      method = msg.delete(:method) || 'GET'
      env['REQUEST_METHOD'] = method.to_s.upcase
      env['QUERY_STRING'] = queryize(msg.delete(:params))
      env['SCRIPT_NAME'] = @route_prefix || ''
      env['PATH_INFO'] = "#{@route_prefix}/#{@resource}/#{msg.delete(:id)}/#{msg.delete(:path)}"
      env.merge!(msg)
      env
    end

    private

    def queryize(params = {})
      params.map do |key, value|
        if value.is_a? Array
          value.map { |v| URI.encode("#{key}[]=#{v}") }
        else
          URI.encode("#{key}=#{value}")
        end
      end.join('&') unless params.nil?
    end
  end
end
