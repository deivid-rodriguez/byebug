# frozen_string_literal: true

require "byebug/history"

module Byebug
  #
  # Interface class for remote use of byebug.
  #
  class RemoteInterface < Interface
    def initialize(socket)
      super()
      @input = socket
      @output = socket
      @error = socket
    end

    def read_command(prompt)
      super("PROMPT #{prompt}")
    end

    def confirm(prompt)
      super("CONFIRM #{prompt}")
    end

    def close
      output.close
    rescue IOError
      errmsg("Error closing the interface...")
    end

    def readline(prompt)
      output.puts(prompt)

      result = input.gets
      raise IOError unless result

      result.chomp
    end
  end
end
