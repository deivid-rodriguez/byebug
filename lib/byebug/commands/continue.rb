module Byebug
  #
  # Implements the continue command.
  #
  # Allows the user to continue execution until the next stopping point, a
  # specific line number or until program termination.
  #
  class ContinueCommand < Command
    def regexp
      /^\s* c(?:ont(?:inue)?)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      if @match[1]
        num, err = get_int(@match[1], 'Continue', 0, nil)
        return errmsg(err) unless num

        filename = File.expand_path(@state.file)
        unless LineCache.trace_line_numbers(filename).member?(num)
          return errmsg("Line #{num} is not a valid stopping point in file")
        end

        Breakpoint.add(filename, num)
      end

      @state.proceed
    end

    class << self
      def names
        %w(continue)
      end

      def description
        %(c[ont[inue]][ <n>]

          Run until program ends, hits a breakpoint or reaches line <n>.)
      end
    end
  end
end
