module Nasreddin
  class APIServer
    def initialize(app, options = {})
      @app = app
      @queue = TorqueBox::Messaging::Queue.start('/queues/foo')
      Thread.new do
        @queue.receive_and_publish do |msg|
          @app.call(msg)
        end
      end
    end

    def call(env)
      @app.call(env)
    end
  end
end
