require 'byebug/history'

module Byebug
  #
  # Interface class for remote use of byebug.
  #
  class RemoteInterface < Interface
    attr_reader :history

    def initialize(socket)
      super()
      @socket = socket
      @history = History.new
    end

    def close
      @socket.close
    rescue IOError
    end

    def confirm(prompt)
      send_command "CONFIRM #{prompt}"
    end

    def read_command(prompt)
      send_command "PROMPT #{prompt}"
    end

    def puts(message)
      @socket.puts(message)
    end

    private

    def send_command(msg)
      @socket.puts msg
      result = @socket.gets
      fail IOError unless result
      result.chomp
    end
  end
end
