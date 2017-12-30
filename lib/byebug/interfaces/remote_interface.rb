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

    def print(message)
      super(message)
    rescue Errno::EPIPE
      nil
    end

    def puts(message)
      super(message)
    rescue Errno::EPIPE
      nil
    end

    def close
      output.close
    end

    def readline(prompt)
      puts(prompt)

      result = input.gets
      return "continue" unless result

      result.chomp
    end
  end
end
