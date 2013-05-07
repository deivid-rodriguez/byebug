module Byebug

  class ConditionCommand < Command # :nodoc:

    def regexp
      /^\s* cond(?:ition)? (?:\s+(\d+)\s*(.*))?$/ix
    end

    def execute
      if not @match[1]
        errmsg "\"condition\" must be followed by breakpoint number and expression\n"
      else
        breakpoints = Byebug.breakpoints.sort_by{|b| b.id }
        largest = breakpoints.inject(0) do |tally, b|
          tally = b.id if b.id > tally
        end
        if 0 == largest
          print "No breakpoints have been set.\n"
          return
        end
        pos = get_int(@match[1], "Condition", 1, largest)
        return unless pos
        breakpoints.each do |b|
          if b.id == pos
            b.expr = @match[2].empty? ? nil : @match[2]
            break
          end
        end

      end
    end

    class << self
      def names
        %w(condition)
      end

      def description
        %{
          cond[ition] nnn[ expr]

          Specify breakpoint number nnn to break only if expr is true. nnn is an
          integer and expr is an expression to be evaluated whenever breakpoint
          nnn is reached. If no expression is specified, the condition is
          removed.
        }
      end
    end
  end

end # module Byebug
