# frozen_string_literal: true
module Byebug
  #
  # Interface class for standard byebug use.
  #
  class LocalInterface < Interface
    EOF_ALIAS = 'continue'.freeze

    def initialize
      super()
      @input = $stdin
      @output = $stdout
      @error = $stderr
    end

    #
    # Reads a single line of input using Readline. If Ctrl-D is pressed, it
    # returns "continue", meaning that program's execution will go on.
    #
    # @param prompt Prompt to be displayed.
    #
    def readline(prompt)
      with_repl_like_sigint { Readline.readline(prompt) || EOF_ALIAS }
    end

    #
    # Yields the block handling Ctrl-C the following way: if pressed while
    # waiting for input, the line is reset to only the prompt and we ask for
    # input again.
    #
    # @note Any external 'INT' traps are overriden during this method.
    #
    def with_repl_like_sigint
      orig_handler = trap('INT') { raise Interrupt }
      yield
    rescue Interrupt
      puts('^C')
      retry
    ensure
      trap('INT', orig_handler)
    end
  end
end
