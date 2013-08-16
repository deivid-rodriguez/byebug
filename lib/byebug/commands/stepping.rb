module Byebug

  # Mix-in module to assist in command parsing.
  module SteppingFunctions
    def parse_stepping_args(command_name, match)
      if match[1].nil?
        force = Command.settings[:forcestep]
      elsif match[1] == '+'
        force = true
      elsif match[1] == '-'
        force = false
      end
      steps = get_int(match[2], command_name, 1)
      return [steps, force]
    end
  end

  # Implements byebug "next" command.
  class NextCommand < Command
    self.allow_in_post_mortem = false
    self.need_context         = true

    def regexp
      /^\s* n(?:ext)?([+-])? (?:\s+(\S+))? \s*$/x
    end

    def execute
      steps, force = parse_stepping_args("Next", @match)
      return unless steps
      @state.context.step_over steps, @state.frame_pos, force
      @state.proceed
    end

    class << self
      def names
        %w(next)
      end

      def description
        %{n[ext][+-]?[ nnn]\tstep over once or nnn times,
          \t\t'+' forces to move to another line.
          \t\t'-' is the opposite of '+' and disables the :forcestep setting.
         }
      end
    end
  end

  # Implements byebug "step" command.
  class StepCommand < Command
    self.allow_in_post_mortem = false
    self.need_context         = true

    def regexp
      /^\s* s(?:tep)?([+-]) ?(?:\s+(\S+))? \s*$/x
    end

    def execute
      steps, force = parse_stepping_args("Step", @match)
      return unless steps
      @state.context.step_into steps, force
      @state.proceed
    end

    class << self
      def names
        %w(step)
      end

      def description
        %{
          s[tep][+-]?[ nnn]\tstep (into methods) once or nnn times
          \t\t'+' forces to move to another line.
          \t\t'-' is the opposite of '+' and disables the :forcestep setting.
         }
      end
    end
  end
end
