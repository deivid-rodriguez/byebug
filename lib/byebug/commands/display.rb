module Byebug
  #
  # Custom display utilities.
  #
  module DisplayFunctions
    def display_expression(exp)
      "#{exp} = #{bb_warning_eval(exp).inspect}"
    end

    def active_display_expressions?
      @state.display.select { |d| d[0] }.size > 0
    end

    def print_display_expressions
      n = 1
      @state.display.each do |d|
        puts "#{n}: #{display_expression(d[1])}" if d[0]
        n += 1
      end
    end
  end

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
      puts "#{@state.display.size}: #{display_expression(exp)}"
    end

    class << self
      def names
        %w(display)
      end

      def description
        %(disp[lay] <expression>

          Add <expression> into display expression list.)
      end
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
        %(disp[lay]        Display expression list.)
      end
    end
  end
end
