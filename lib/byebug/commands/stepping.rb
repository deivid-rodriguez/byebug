require 'byebug/command'

module Byebug
  #
  # Implements the next functionality.
  #
  # Allows the user the continue execution until the next instruction in the
  # current frame.
  #
  class NextCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* n(?:ext)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      steps, err = parse_steps(@match[1], 'Next')
      return errmsg(err) unless steps

      @state.context.step_over(steps, @state.frame)
      @state.proceed
    end

    class << self
      def names
        %w(next)
      end

      def description
        prettify <<-EOD
          n[ext][ nnn]

          Steps over once or nnn times.
        EOD
      end
    end
  end

  #
  # Implements the step functionality.
  #
  # Allows the user the continue execution until the next instruction, possibily
  # in a different frame. Use step to step into method calls or blocks.
  #
  class StepCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* s(?:tep)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      steps, err = parse_steps(@match[1], 'Steps')
      return errmsg(err) unless steps

      @state.context.step_into(steps, @state.frame)
      @state.proceed
    end

    class << self
      def names
        %w(step)
      end

      def description
        prettify <<-EOD
          s[tep][ nnn]

          Steps (into methods) once or nnn times.
        EOD
      end
    end
  end
end
