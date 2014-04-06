module Byebug
  class RemoteInterface < Interface
    attr_accessor :hist_save, :hist_file

    def initialize(socket)
      @socket = socket
      @hist_save = false
      @hist_file = ''
      # Do we read the histfile?
      # open(@histfile, 'r') do |file|
      #   file.each do |line|
      #     line.chomp!
      #     Readline::HISTORY << line
      #   end
      # end if File.exist?(@histfile)
        @restart_file = nil
    end

    def close
      @socket.close
    rescue IOError
    end

    def confirm(prompt)
      send_command "CONFIRM #{prompt}"
    end

    def finalize
    end

    def read_command(prompt)
      send_command "PROMPT #{prompt}"
    end

    def readline_support?
      false
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
