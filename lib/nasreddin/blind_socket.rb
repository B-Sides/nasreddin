require 'zmq'
require 'socket'

module Nasreddin
  class BlindSocket
    def initialize(port, *targets)
      @ctx = ZMQ::Context.new
      @cli_out = @ctx.socket(ZMQ::PUSH)
      @cli_in = @ctx.socket(ZMQ::SUB)

      targets.each do |t|
        @cli_out.connect(t)
      end
      @cli_in.bind("tcp://*:#{port}")

      @serial_gen = Random.new(Random.new_seed)
      my_addr = Socket.ip_address_list
                      .select { |a| a.afamily == 2 }.compact
                      .reject { |a| a.ipv4_loopback? || a.ipv4_private? }.first
      @addr = "tcp://#{my_addr.ip_address}:#{port}"
    end

    def connect(srv)
      @cli_out.connect(srv)
    end

    def send(msg)
      @serial = @serial_gen.bytes(12).unpack('h*')[0]
      @cli_in.setsockopt(ZMQ::SUBSCRIBE, @serial)
      @cli_out.send("#{@addr} #{@serial} #{msg}")
    end

    def recv
      resp = @cli_in.recv.split(' ')
      @cli_in.setsockopt(ZMQ::UNSUBSCRIBE, resp.shift)
      resp.join(' ')
    end

    def close
      @cli_in.close
      @cli_out.close
      @ctx.close
    end
  end
end
