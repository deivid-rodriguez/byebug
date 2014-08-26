module Byebug
  #
  # Implements exception catching.
  #
  # Enables the user to catch unhandled assertion when they happen.
  #
  class CatchCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* cat(?:ch)? (?:\s+(\S+))? (?:\s+(off))? \s*$/x
    end

    def execute
      excn = @match[1]
      return info_catch unless excn

      if !@match[2]
        if 'off' == @match[1]
          Byebug.catchpoints.clear if
            confirm('Delete all catchpoints? (y or n) ')
        else
          puts "Warning #{@match[1]} is not known to be a Class" unless
            bb_eval "#{@match[1]}.is_a?(Class)", get_binding
          Byebug.add_catchpoint @match[1]
          puts "Catching exception #{@match[1]}."
        end
      elsif @match[2] != 'off'
        errmsg "Off expected. Got #{@match[2]}"
      elsif Byebug.catchpoints.member?(@match[1])
        Byebug.catchpoints.delete @match[1]
        errmsg "Catch for exception #{match[1]} removed"
      else
        errmsg "Catch for exception #{@match[1]} not found"
      end
    end

    class << self
      def names
        %w(catch)
      end

      def description
        %(cat[ch][ (off|<exception>[ off])]

          "catch" lists catchpoints.
          "catch off" deletes all catchpoints.
          "catch <exception>" enables handling <exception>.
          "catch <exception> off" disables handling <exception>.)
      end
    end
  end
end
