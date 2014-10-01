require 'byebug/history'

#
# Namespace for all of byebug's code
#
module Byebug
  #
  # Main Interface class
  #
  # Contains common functionality to all implemented interfaces.
  #
  class Interface
    attr_accessor :command_queue, :history
    attr_reader :input, :output, :error

    def initialize
      @command_queue, @history = [], History.new
    end

    #
    # Reads a command from the input stream.
    #
    def read_command(prompt)
      readline(prompt, true)
    end

    #
    # Prints an error message to the error stream.
    #
    def errmsg(message)
      error.print("*** #{message}\n")
    end

    #
    # Prints an output message to the output stream.
    #
    def puts(message)
      output.puts(message)
    end

    #
    # Confirms user introduced an affirmative response to the input stream.
    #
    def confirm(prompt)
      readline(prompt, false) == 'y'
    end

    def close
    end
  end

  require 'byebug/interfaces/local_interface'
  require 'byebug/interfaces/script_interface'
  require 'byebug/interfaces/remote_interface'
end
