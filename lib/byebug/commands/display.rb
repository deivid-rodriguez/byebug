module Byebug
  module DisplayFunctions
    def display_expression(exp)
      print "#{exp} = #{bb_warning_eval(exp).inspect}\n"
    end

    def active_display_expressions?
      @state.display.select{|d| d[0]}.size > 0
    end

    def print_display_expressions
      n = 1
      for d in @state.display
        if d[0]
          print "#{n}: "
          display_expression(d[1])
        end
        n += 1
      end
    end
  end

  class AddDisplayCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* disp(?:lay)? \s+ (.+) \s*$/x
    end

    def execute
      exp = @match[1]
      @state.display.push [true, exp]
      print "#{@state.display.size}: "
      display_expression(exp)
    end

    class << self
      def names
        %w(display)
      end

      def description
        %{disp[lay] <expression>\tadd expression into display expression list}
      end
    end
  end

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
        %{disp[lay]\t\tdisplay expression list}
      end
    end
  end
end
