module Byebug
  #
  # Custom interface for easier assertions
  #
  class TestInterface < Interface
    attr_reader :input_queue, :output_queue, :error_queue, :confirm_queue

    attr_accessor :test_block

    def initialize
      super()
      @input_queue, @output_queue = [], []
      @error_queue, @confirm_queue = [], []
    end

    def errmsg(*args)
      @error_queue.push(*args)
    end

    def read_command(*)
      return readline(true) unless @input_queue.empty?

      if test_block
        test_block.call
        self.test_block = nil
      end
    end

    def puts(*args)
      @output_queue.push(*args)
    end

    def confirm(message)
      @confirm_queue << message
      readline(false)
    end

    def close
    end

    def inspect
      [
        "input_queue: #{input_queue.inspect}",
        "output_queue: #{output_queue.inspect}",
        "error_queue: #{error_queue.inspect}",
        "confirm_queue: #{confirm_queue.inspect}"
      ].join("\n")
    end

    private

    def readline(hist)
      cmd = @input_queue.shift
      cmd = cmd.is_a?(Proc) ? cmd.call : cmd
      save_history(cmd) unless !hist
      cmd
    end
  end
end
