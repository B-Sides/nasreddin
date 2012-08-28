require 'stringio'
require 'uri'

module Nasreddin

  class APIServer

    def initialize(app, options = {})
      @app = app
      @threads = []
      if options[:resources]
         options[:resources].each do |resource|
            @threads << Thread.new { Nasreddin::APIServerResource.new(resource).run }
        end
      else
        $stderr.puts "WARNING: Nasreddin::APIServer is being used without any resources specified!"
      end
      @threads.map(&:join)
    end

    def call(env)
      @app.call(env)
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

    def initialize(resource)
      @resource = resource
      @queue = TorqueBox::Messaging::Queue.start("/queues/#{@resource}", durable: false)
    end

    def run
      begin
        loop do
          @queue.receive_and_publish do |msg|
              handle_message(msg)
          end
        end
      ensure
        @queue.stop
      end
    end

    private

    def handle_message(msg)
      begin
        env = DEFAULT_ENV.clone
        env['rack.url_scheme'] = (msg.delete(:secure) ? 'https' : 'http')
        method = msg.delete(:method) || 'GET'
        env['REQUEST_METHOD'] = method.to_s.upcase
        env['QUERY_STRING'] = queryize(msg.delete(:params))
        env['PATH_INFO'] = "#{options[:route_prefix]}/#{resource}/#{msg.delete(:id)}/#{msg.delete(:path)}"

        env.merge!(msg)
        status, headers, body = @app.call(env)

        resp = ''
        body.each { |d| resp += d.to_s }
        body.close

      rescue Exception => err
        resp = "#{err.message}\n\n#{err.backtrace.join("\n")}"
      end

      [status, headers, resp]
    end

    def queryize(params = {})
      params.map { |key, value| URI.encode("#{key}=#{value}") }.join('&') unless params.nil?
    end
  end

end
