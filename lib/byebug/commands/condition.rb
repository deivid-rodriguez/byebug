module Byebug
  #
  # Implements conditions on breakpoints.
  #
  # Adds the ability to stop on breakpoints only under certain conditions.
  #
  class ConditionCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* cond(?:ition)? (?:\s+(\d+)(?:\s+(.*))?)? \s*$/x
    end

    def execute
      return puts(ConditionCommand.help) unless @match[1]

      breakpoints = Byebug.breakpoints.sort_by { |b| b.id }
      return errmsg('No breakpoints have been set') unless breakpoints.any?

      pos, err = get_int(@match[1], 'Condition', 1)
      return errmsg(err) if err

      breakpoint = breakpoints.find { |b| b.id == pos }
      return errmsg('Invalid breakpoint id. Use "info breakpoint" to find ' \
                    'out the correct id') unless breakpoint

      return errmsg("Incorrect expression \"#{@match[2]}\", " \
                    'breakpoint not changed') unless syntax_valid?(@match[2])

      breakpoint.expr = @match[2]
    end

    class << self
      def names
        %w(condition)
      end

      def description
        %(cond[ition] <n>[ expr]

          Specify breakpoint number <n> to break only if <expr> is true. <n> is
          an integer and <expr> is an expression to be evaluated whenever
          breakpoint <n> is reached. If no expression is specified, the
          condition is removed.)
      end
    end
  end
end
