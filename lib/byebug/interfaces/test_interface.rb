module Byebug
  #
  # Custom interface for easier assertions
  #
  class TestInterface < Interface
    attr_accessor :test_block

    def initialize
      super()
      @input, @output, @error = [], [], []
    end

    def errmsg(message)
      error.concat(message.to_s.split("\n"))
    end

    def print(message)
      output.concat(message.to_s.split("\n"))
    end

    def puts(message)
      output.concat(message.to_s.split("\n"))
    end

    def read_command(prompt)
      return readline(prompt, true) unless input.empty?

      return unless test_block

      test_block.call
      self.test_block = nil
    end

    def inspect
      [
        'Input:', input.join("\n"),
        'Output:', output.join("\n"),
        'Error:', error.join("\n")
      ].join("\n")
    end

    def readline(prompt, hist)
      puts(prompt)

      cmd = input.shift
      cmd = cmd.is_a?(Proc) ? cmd.call : cmd
      @history.push(cmd) if hist
      cmd
    end
  end
end
