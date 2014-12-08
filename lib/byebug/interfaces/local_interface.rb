module Byebug
  #
  # Interface class for standard byebug use.
  #
  class LocalInterface < Interface
    def initialize
      super()
      @input, @output, @error = STDIN, STDOUT, STDERR
    end

    #
    # Reads a single line of input using Readline. If Ctrl-C is pressed in the
    # middle of input, the line is reset to only the prompt and we ask for input
    # again.
    #
    # @param prompt Prompt to be displayed.
    #
    def readline(prompt)
      Readline.readline(prompt, false)
    rescue Interrupt
      puts('^C')
      retry
    end
  end
end
