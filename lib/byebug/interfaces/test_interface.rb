module Byebug
  #
  # Custom interface for easier assertions
  #
  class TestInterface < Interface
    attr_accessor :test_block

    def initialize
      super()
      @input = []
      @output = []
      @error = []
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
      cmd = super(prompt)

      return cmd unless cmd.nil? && test_block

      test_block.call
      self.test_block = nil
    end

    def clear
      @input = []
      @output = []
      @error = []
      history.clear
    end

    def inspect
      [
        'Input:', input.join("\n"),
        'Output:', output.join("\n"),
        'Error:', error.join("\n")
      ].join("\n")
    end

    def readline(prompt)
      puts(prompt)

      cmd = input.shift
      cmd.is_a?(Proc) ? cmd.call : cmd
    end
  end
end
