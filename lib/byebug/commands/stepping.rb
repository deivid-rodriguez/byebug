module Byebug
  #
  # Mixin to assist command parsing
  #
  module SteppingFunctions
    def parse_force(str)
      return Setting[:forcestep] unless str

      case str
      when '+' then
        return true
      when '-' then
        return false
      end

      nil
    end
  end

  #
  # Implements the next functionality.
  #
  # Allows the user the continue execution until the next instruction in the
  # current frame.
  #
  class NextCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* n(?:ext)?([+-])? (?:\s+(\S+))? \s*$/x
    end

    def execute
      if @match[2]
        steps, err = get_int(@match[2], 'Next', 1)
        return errmsg(err) unless steps
      end

      force = parse_force(@match[1])

      @state.context.step_over(steps || 1, @state.frame_pos, force)
      @state.proceed
    end

    class << self
      def names
        %w(next)
      end

      def description
        %(n[ext][+-]?[ nnn]

        Steps over once or nnn times.
          '+' forces to move to another line.
          '-' is the opposite of '+' and disables the :forcestep setting.)
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
      /^\s* s(?:tep)?([+-]) ?(?:\s+(\S+))? \s*$/x
    end

    def execute
      if @match[2]
        steps, err = get_int(@match[2], 'Step', 1)
        return errmsg(err) unless steps
      end

      @state.context.step_into(steps || 1, parse_force(@match[1]))
      @state.proceed
    end

    class << self
      def names
        %w(step)
      end

      def description
        %{s[tep][+-]?[ nnn]

          Steps (into methods) once or nnn times.
            '+' forces to move to another line.
            '-' is the opposite of '+' and disables the :forcestep setting.}
      end
    end
  end
end
