module Byebug

  # Implements byebug "skip" command
  class SkipCommand < Command
    self.allow_in_control = true

    def regexp
      / ^\s*
         sk(?:ip)? \s*
         $
      /ix
    end

    def execute
      Byebug::skip_next_exception
      print "ok\n"
    end

    class << self
      def help_command
        %w[skip]
      end

      def help(cmd)
        %{
          sk[ip]\tskip the next thrown exception

          This is useful if you've explicitly caught an exception through
          the "catch" command, and wish to pass the exception on to the
          code that you're debugging.
         }
     end
    end
  end
end
