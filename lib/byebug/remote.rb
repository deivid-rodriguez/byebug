# frozen_string_literal: true

require "socket"
require "byebug/processors/control_processor"
require "byebug/remote/client"

#
# Remote debugging functionality.
#
# @todo Refactor & add tests
#
module Byebug
  # Port number used for remote debugging
  PORT = 8989 unless defined?(PORT)

  class << self
    # If in remote mode, wait for the remote connection
    attr_accessor :wait_connection

    # The actual port that the server is started at
    attr_reader :actual_port

    # The actual port that the control server is started at
    attr_reader :actual_control_port

    #
    # Interrupts the current thread
    #
    def interrupt
      current_context.interrupt
    end

    #
    # Starts the remote server main thread
    #
    def start_server(host = nil, port = PORT)
      return if @thread

      Context.interface = nil
      start

      start_control(host, port.zero? ? 0 : port + 1)

      if wait_connection
        mutex = Mutex.new
        proceed = ConditionVariable.new
      end

      server = TCPServer.new(host, port)
      @actual_port = server.addr[1]

      yield if block_given?

      @thread = DebugThread.new do
        while (session = server.accept)
          Context.interface = RemoteInterface.new(session)
          mutex.synchronize { proceed.signal } if wait_connection
        end
      end

      mutex.synchronize { proceed.wait(mutex) } if wait_connection
    end

    #
    # Starts the remote server control thread
    #
    def start_control(host = nil, port = PORT + 1)
      return @actual_control_port if @control_thread
      server = TCPServer.new(host, port)
      @actual_control_port = server.addr[1]

      @control_thread = DebugThread.new do
        while (session = server.accept)
          context = Byebug.current_context
          interface = RemoteInterface.new(session)

          ControlProcessor.new(context, interface).process_commands
        end
      end

      @actual_control_port
    end

    #
    # Connects to the remote byebug
    #
    def start_client(host = "localhost", port = PORT)
      client.start(host, port)
    end

    def parse_host_and_port(host_port_spec)
      location = host_port_spec.split(":")
      location[1] ? [location[0], location[1].to_i] : ["localhost", location[0]]
    end

    private

    def client
      @client ||= Remote::Client.new(LocalInterface.new)
    end
  end
end
