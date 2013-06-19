module Byebug

  class CatchCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* cat(?:ch)?
           (?:\s+ (\S+))?
           (?:\s+ (off))? \s* $/ix
    end

    def execute
      excn = @match[1]
      return info_catch unless excn

      if not @match[2]
        if 'off' == @match[1]
          Byebug.catchpoints.clear if
            confirm("Delete all catchpoints? (y or n) ")
        else
          print "Warning #{@match[1]} is not known to be a Class\n" unless
            debug_eval "#{@match[1]}.is_a?(Class)", get_binding
          Byebug.add_catchpoint @match[1]
          print "Catch exception #{@match[1]}.\n"
        end
      elsif @match[2] != 'off'
        errmsg "Off expected. Got #{@match[2]}\n"
      elsif Byebug.catchpoints.member?(@match[1])
        Byebug.catchpoints.delete @match[1]
        print "Catch for exception #{match[1]} removed.\n"
      else
        return errmsg "Catch for exception #{@match[1]} not found\n"
      end
    end

    class << self
      def names
        %w(catch)
      end

      def description
        %{cat[ch]\t\tsame as "info catch"
          cat[ch] <exception-name> [on|off]
          \tIntercept <exception-name> when there would otherwise be no handler.
          \tWith an "on" or "off", turn handling the exception on or off.
          cat[ch] off\tdelete all catchpoints}
      end
    end
  end
end
