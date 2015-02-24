require 'byebug/command'

module Byebug
  #
  # Implements the functionality of adding custom expressions to be displayed
  # every time the debugger stops.
  #
  class AddDisplayCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* disp(?:lay)? \s+ (.+) \s*$/x
    end

    def execute
      exp = @match[1]
      @state.display.push [true, exp]
      display_expression(exp)
    end

    class << self
      def names
        %w(display)
      end

      def description
        prettify <<-EOD
          disp[lay] <expression>

          Add <expression> into display expression list.
        EOD
      end
    end

    private

    def display_expression(exp)
      print pr('display.result',
               n: @state.display.size,
               exp: exp,
               result: bb_warning_eval(exp).inspect)
    end
  end

  #
  # Displays the value of enabled expressions.
  #
  class DisplayCommand < Command
    self.allow_in_post_mortem = false

    def self.always_run
      2
    end

    def regexp
      /^\s* disp(?:lay)? \s*$/x
    end

    def execute
      print_display_expressions
    end

    class << self
      def names
        %w(display)
      end

      def description
        prettify <<-EOD
          disp[lay] Display expression list.
        EOD
      end
    end

    private

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
