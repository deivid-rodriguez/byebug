# frozen_string_literal: true

require_relative "../../command"
require_relative "../../helpers/parse"

module Byebug
  #
  # Reopens the +condition+ command to define the +expression+ subcommand
  #
  class ConditionCommand < Command
    #
    # Information about arguments of the current method/block
    #
    class ExpressionCommand < Command
      include Helpers::ParseHelper

      self.allow_in_post_mortem = true

      def self.regexp
        /
          ^\s*
          (?:expr(?:ession)?\s+)?
          (?:
            (?<number>\d+) # breakpoint number
            (?:\s+(?<expression>.*))? # conditional expression
          )?
          \s*$
        /x
      end

      def self.description
        <<-DESCRIPTION
          cond[ition] [expr[ession]] <n> [<expr>]

          #{short_description}

          Set or unset the conditional expression of breakpoint number <n>. If a
          conditional expression is set, the breakpoint will not break unless the
          expression evaluates to true. If <expr> is omitted, the condition
          expression is removed.

        DESCRIPTION
      end

      def self.short_description
        "Set a conditional expression on a breakpoint"
      end

      def execute
        return puts(help) unless @match && @match[:number]

        breakpoints = Byebug.breakpoints.sort_by(&:id)
        return errmsg(pr("condition.errors.no_breakpoints")) if breakpoints.empty?

        pos, err = get_int(@match[:number], "Condition", 1)
        return errmsg(err) if err

        breakpoint = breakpoints.find { |b| b.id == pos }
        return errmsg(pr("break.errors.no_breakpoint")) unless breakpoint

        return errmsg(pr("break.errors.not_changed", expr: @match[:expression])) unless syntax_valid?(@match[:expression])

        breakpoint.expr = @match[:expression]
      end
    end
  end
end
