module Byebug
  #
  # Mixin to assist command parsing
  #
  module SteppingFunctions
    def parse_stepping_args(command_name, match)
      if match[1].nil?
        force = Setting[:forcestep]
      elsif match[1] == '+'
        force = true
      elsif match[1] == '-'
        force = false
      end
      steps = get_int(match[2], command_name, 1)
      [steps, force]
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
      steps, force = parse_stepping_args('Next', @match)
      return unless steps
      @state.context.step_over(steps, @state.frame_pos, force)
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
      steps, force = parse_stepping_args('Step', @match)
      return unless steps
      @state.context.step_into steps, force
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
