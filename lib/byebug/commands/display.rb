require 'byebug/command'

module Byebug
  #
  # Custom expressions to be displayed every time the debugger stops.
  #
  class DisplayCommand < Command
    self.allow_in_post_mortem = false

    def self.always_run
      2
    end

    def regexp
      /^\s* disp(?:lay)? (?:\s+ (.+))? \s*$/x
    end

    def execute
      return print_display_expressions unless @match && @match[1]

      @state.display.push [true, @match[1]]
      display_expression(@match[1])
    end

    def description
      <<-EOD
        disp[lay][ <expression>]

        If <expression> specified, adds <expression> into display expression
        list. Otherwise, it lists all expressions.
      EOD
    end

    private

    def display_expression(exp)
      print pr('display.result',
               n: @state.display.size,
               exp: exp,
               result: bb_warning_eval(exp).inspect)
    end

    def print_display_expressions
      result = prc('display.result', @state.display) do |item, index|
        is_active, expression = item
        if is_active
          { n: index + 1,
            exp: expression,
            result: bb_warning_eval(expression).inspect }
        end
      end

      print result
    end
  end
end
