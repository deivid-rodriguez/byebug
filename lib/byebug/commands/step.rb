require 'byebug/command'
require 'byebug/helpers/parse'

module Byebug
  #
  # Implements the step functionality.
  #
  # Allows the user the continue execution until the next instruction, possibily
  # in a different frame. Use step to step into method calls or blocks.
  #
  class StepCommand < Command
    include Helpers::ParseHelper

    self.allow_in_post_mortem = false

    def regexp
      /^\s* s(?:tep)? (?:\s+(\S+))? \s*$/x
    end

    def description
      <<-EOD
        s[tep][ times]

        #{short_description}
      EOD
    end

    def short_description
      'Steps into blocks or methods one or more times'
    end

    def execute
      steps, err = parse_steps(@match[1], 'Steps')
      return errmsg(err) unless steps

      @state.context.step_into(steps, @state.frame)
      @state.proceed
    end
  end
end
