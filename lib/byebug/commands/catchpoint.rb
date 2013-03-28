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
      if not excn
        # No args given.
        info_catch
      elsif not @match[2]
        # One arg given.
        if 'off' == excn
          Byebug.catchpoints.clear if
            confirm("Delete all catchpoints? (y or n) ")
        else
          binding = @state.context ? get_binding : TOPLEVEL_BINDING
          unless debug_eval("#{excn}.is_a?(Class)", binding)
            print "Warning #{excn} is not known to be a Class\n"
          end
          Byebug.add_catchpoint(excn)
          print "Catch exception %s.\n", excn
        end
      elsif @match[2] != 'off'
        errmsg "Off expected. Got %s\n", @match[2]
      elsif Byebug.catchpoints.member?(excn)
        Byebug.catchpoints.delete(excn)
        print "Catch for exception %s removed.\n", excn
      else
        errmsg "Catch for exception %s not found.\n", excn
      end
    end

    class << self
      def help_command
        'catch'
      end

      def help(cmd)
        %{
          cat[ch]\t\tsame as "info catch"
          cat[ch] <exception-name> [on|off]
\tIntercept <exception-name> when there would otherwise be no handler.
\tWith an "on" or "off", turn handling the exception on or off.
          cat[ch] off\tdelete all catchpoints
        }
      end
    end
  end
end
