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

  class DeleteDisplayCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* undisp(?:lay)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      unless pos = @match[1]
        if confirm("Clear all expressions? (y/n) ")
          for d in @state.display
            d[0] = false
          end
        end
      else
        pos = get_int(pos, "Undisplay")
        return unless pos
        if @state.display[pos-1]
          @state.display[pos-1][0] = nil
        else
          errmsg "Display expression %d is not defined.\n", pos
        end
      end
    end

    class << self
      def names
        %w(undisplay)
      end

      def description
        %{undisp[lay][ nnn]

          Cancel some expressions to be displayed when program stops. Arguments
          are the code numbers of the expressions to stop displaying. No
          argument means cancel all automatic-display expressions. "delete
          display" has the same effect as this command. Do "info display" to see
          the current list of code numbers.}
      end
    end
  end
end
