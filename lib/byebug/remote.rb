require 'socket'

module Byebug

  # Port number used for remote debugging
  PORT = 8989 unless defined?(PORT)

  class << self

    # If in remote mode, wait for the remote connection
    attr_accessor :wait_connection

    # The actual port that the server is started at
    attr_accessor :actual_port
    attr_reader :actual_control_port

    #
    # Interrupts the current thread
    #
    def interrupt
      current_context.interrupt
    end

    #
    # Starts a remote byebug
    #
    def start_server(host = nil, port = PORT)
      return if @thread

      self.interface = nil
      start

      start_control(host, port == 0 ? 0 : port + 1)

      yield if block_given?

      mutex = Mutex.new
      proceed = ConditionVariable.new

      server = TCPServer.new(host, port)
      self.actual_port = server.addr[1]
      @thread = DebugThread.new do
        while (session = server.accept)
          self.interface = RemoteInterface.new(session)
          if wait_connection
            mutex.synchronize do
              proceed.signal
            end
          end
        end
      end
      if wait_connection
        mutex.synchronize do
          proceed.wait(mutex)
        end
      end
    end

    def start_control(host = nil, ctrl_port = PORT + 1)
       return @actual_control_port if @control_thread
       server = TCPServer.new(host, ctrl_port)
       @actual_control_port = server.addr[1]
       @control_thread = Thread.new do
         while (session = server.accept)
           interface = RemoteInterface.new(session)
           ControlCommandProcessor.new(interface).process_commands
         end
       end
       @actual_control_port
    end

    #
    # Connects to the remote byebug
    #
    def start_client(host = 'localhost', port = PORT)
      interface = Byebug::LocalInterface.new
      socket = TCPSocket.new(host, port)
      puts "Connected."

      catch(:exit) do
        while (line = socket.gets)
          case line
          when /^PROMPT (.*)$/
            input = interface.read_command($1)
            throw :exit unless input
            socket.puts input
          when /^CONFIRM (.*)$/
            input = interface.confirm($1)
            throw :exit unless input
            socket.puts input
          else
            print line
          end
        end
      end
      socket.close
    end
  end
end
