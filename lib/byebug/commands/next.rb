require 'byebug/command'
require 'byebug/helpers/parse'

module Byebug
  #
  # Implements the next functionality.
  #
  # Allows the user the continue execution until the next instruction in the
  # current frame.
  #
  class NextCommand < Command
    include Helpers::ParseHelper

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

    def description
      <<-EOD
        n[ext][ nnn]

        Steps over once or nnn times.
      EOD
    end
  end
end
