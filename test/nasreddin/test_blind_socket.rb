require 'nasreddin/blind_socket'
require 'zmq'

ADDR = Socket.ip_address_list
             .select { |a| a.afamily == 2 }.compact
             .reject { |a| a.ipv4_loopback? || a.ipv4_private? }
             .first.ip_address

def dummy_server(port)
  Thread.new do
    ctx = ZMQ::Context.new
    srv_in = ctx.socket ZMQ::PULL
    srv_in.bind("tcp://*:#{port}")
    Thread.current[:res] = srv_in.recv
    srv_in.close
    ctx.close
  end
end

def dummy_responder(port)
  Thread.new do
    ctx = ZMQ::Context.new
    srv_in = ctx.socket ZMQ::PULL
    srv_out = ctx.socket ZMQ::PUB
    srv_in.bind("tcp://*:#{port}")
    msg = srv_in.recv.split(' ')
    srv_out.connect(msg.shift)
    srv_out.send(msg.join(' '))
    srv_in.close
    srv_out.close
    ctx.close
  end
end

describe Nasreddin::BlindSocket do
  it 'must be instantiated with a port' do
    -> { Nasreddin::BlindSocket.new }.should.raise(ArgumentError)
    -> { Nasreddin::BlindSocket.new(5005).close }.should.not.raise(ArgumentError)
  end

  it 'can be instantiated with a list of sockets to bind' do
    -> {
      Nasreddin::BlindSocket.new(5005, "tcp://#{ADDR}:5001", "tcp://#{ADDR}:5002").close
    }.should.not.raise(ArgumentError)
  end

  describe 'connected to one endpoint' do
    it 'is able to blindly send messages' do
      t = dummy_server(5001)

      sock = Nasreddin::BlindSocket.new(5005, "tcp://#{ADDR}:5001")
      sock.send('test')
      t.join
      sock.close

      t[:res].split(' ').last.should.equal 'test'
    end

    it 'can connect to the server after creation' do
      t = dummy_server(5001)

      sock = Nasreddin::BlindSocket.new(5005)
      sock.connect("tcp://#{ADDR}:5001")
      sock.send('test')
      t.join
      sock.close

      t[:res].split(' ').last.should.equal 'test'
    end

    it 'can receive a response' do
      t = dummy_responder(5001)

      sock = Nasreddin::BlindSocket.new(5005)
      sock.connect('tcp://localhost:5001')
      sock.send('hello')

      res = sock.recv
      res.should.equal 'hello'

      t.join
      sock.close
    end
  end

  describe 'connected to two endpoints' do
    it 'is able to blindly send messages' do
      t1 = dummy_server(5001)
      t2 = dummy_server(5002)
      ts = [t1, t2]

      sock = Nasreddin::BlindSocket.new(5005, "tcp://#{ADDR}:5001", "tcp://#{ADDR}:5002")
      sock.send('test')
      sock.close
      sleep(1)

      ts.map { |t| !t[:res].nil? && t[:res].split(' ').last }.should.include? 'test'
      ts.each(&:kill)
    end

    it 'can receive a response from a random server' do
      t1 = dummy_responder(5001)
      t2 = dummy_responder(5002)
      ts = [t1, t2]

      sock = Nasreddin::BlindSocket.new(5005)
      sock.connect('tcp://localhost:5001')
      sock.connect('tcp://localhost:5002')
      sock.send('hello')

      res = sock.recv
      res.should.equal 'hello'

      ts.each(&:kill)
      sock.close
    end
  end
end
