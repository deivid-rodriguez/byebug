module Byebug
  #
  # Remove expressions from display list.
  #
  class UndisplayCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* undisp(?:lay)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      if @match[1]
        pos, err = get_int(@match[1], 'Undisplay', 1, @state.display.size)
        return errmsg(err) unless err.nil?

        unless @state.display[pos - 1]
          return errmsg("Display expression #{pos} is not defined.")
        end

        @state.display[pos - 1][0] = nil
      else
        return unless confirm('Clear all expressions? (y/n) ')

        @state.display.each { |d| d[0] = false }
      end
    end

    class << self
      def names
        %w(undisplay)
      end

      def description
        %(undisp[lay][ nnn]

          Cancel some expressions to be displayed when program stops. Arguments
          are the code numbers of the expressions to stop displaying. No
          argument means cancel all automatic-display expressions. "delete
          display" has the same effect as this command. Do "info display" to see
          the current list of code numbers.)
      end
    end
  end
end
