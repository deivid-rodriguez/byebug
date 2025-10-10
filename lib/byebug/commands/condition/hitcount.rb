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
    class HitCountCommand < Command
      include Helpers::ParseHelper

      self.allow_in_post_mortem = true

      def self.regexp
        /
          ^\s*
          hit(?:\s?count)?
          (?:\s+
            (?<number>\d+) # breakpoint number
            (?:\s+
              (?<operation>[\w><=%]+) # hit condition
              \s+(?<value>\d+) # value
            )?
          )?
          \s*$
        /x
      end

      def self.description
        <<-DESCRIPTION
          cond[ition] hit[[ ]count] <n> [<op> <value>]

          #{short_description}

          Set or unset the hit condition of breakpoint number <n>. If a hit
          condition is set, the breakpoint will not break unless its hit count
          meets the hit condition. If <op> <value> is omitted, the condition
          expression is removed. <op> can be gt, ge, eq, mod, or the symbolic
          equivalent.
        DESCRIPTION
      end

      def self.short_description
        "Set a hit condition on a breakpoint"
      end

      def execute
        return puts(help) unless @match && @match[:number]

        breakpoints = Byebug.breakpoints.sort_by(&:id)
        return errmsg(pr("condition.errors.no_breakpoints")) if breakpoints.empty?

        pos, err = get_int(@match[:number], "Condition", 1)
        return errmsg(err) if err

        breakpoint = breakpoints.find { |b| b.id == pos }
        return errmsg(pr("break.errors.no_breakpoint")) unless breakpoint

        v = @match[:value].to_i
        case @match[:operation]
        when nil
          breakpoint.hit_condition = nil

        when 'gt', '>'
          breakpoint.hit_condition = :greater_or_equal
          breakpoint.hit_value = v + 1
        when 'ge', '>='
          breakpoint.hit_condition = :greater_or_equal
          breakpoint.hit_value = v
        when 'eq', '=', '==', '==='
          breakpoint.hit_condition = :equal
          breakpoint.hit_value = v
        when 'mod', '%'
          breakpoint.hit_condition = :modulo
          breakpoint.hit_value = v
        else
          return errmsg(pr("break.errors.hit_condition", cond: @match[:operation]))
        end
      end
    end
  end
end
