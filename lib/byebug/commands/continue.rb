module Byebug
  #
  # Implements the continue command.
  #
  # Allows the user to continue execution until the next stopping point, a
  # specific line number or until program termination.
  #
  class ContinueCommand < Command
    self.allow_in_post_mortem = true

    def regexp
      /^\s* c(?:ont(?:inue)?)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      if @match[1] && !@state.context.dead?
        filename = File.expand_path(@state.file)
        line_number = get_int(@match[1], 'Continue', 0, nil, 0)
        return unless line_number

        unless LineCache.trace_line_numbers(filename).member?(line_number)
          return errmsg "Line #{line_number} is not a valid stopping point in file\n"
        end
        Byebug.add_breakpoint filename, line_number
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
