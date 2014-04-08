require 'byebug/history'

module Byebug
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

    def print(*args)
      @socket.printf(escape(format(*args)))
    end

    private

      def send_command(msg)
        @socket.puts msg
        result = @socket.gets
        raise IOError unless result
        result.chomp
      end
  end
end
