require 'byebug/command'
require 'byebug/helpers/parse'

module Byebug
  #
  # Implements the continue command.
  #
  # Allows the user to continue execution until the next stopping point, a
  # specific line number or until program termination.
  #
  class ContinueCommand < Command
    include Helpers::ParseHelper

    def regexp
      /^\s* c(?:ont(?:inue)?)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      if @match[1]
        num, err = get_int(@match[1], 'Continue', 0, nil)
        return errmsg(err) unless num

        filename = File.expand_path(@state.file)
        unless Breakpoint.potential_line?(filename, num)
          return errmsg(pr('continue.errors.unstopped_line', line: num))
        end

        Breakpoint.add(filename, num)
      end

      @state.proceed
    end

    def description
      <<-EOD
        c[ont[inue]][ <n>]

        Run until program ends, hits a breakpoint or reaches line <n>.
      EOD
    end
  end
end
