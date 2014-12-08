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

      breakpoints = Byebug.breakpoints.sort_by(&:id)
      return errmsg(pr('condition.errors.no_breakpoints')) if breakpoints.empty?

      pos, err = get_int(@match[1], 'Condition', 1)
      return errmsg(err) if err

      breakpoint = breakpoints.find { |b| b.id == pos }
      return errmsg(pr('breakpoints.errors.no_breakpoint')) unless breakpoint

      unless syntax_valid?(@match[2])
        return errmsg(pr('breakpoints.errors.not_changed', expr: @match[2]))
      end

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
