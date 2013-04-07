module Byebug
  class TraceCommand < Command # :nodoc:
    def regexp
      /^\s* tr(?:ace)? (?: \s+ (\S+))      # on | off | var(iable)
                       (?: \s+ (\S+))?     # (all | variable-name)?
                       (?: \s+ (\S+))? \s* # (stop | nostop)?
       $/ix
    end

    def execute
      if @match[1] =~ /on|off/
        onoff = 'on' == @match[1]
        #if @match[2]
          Byebug.tracing = onoff
          print "Tracing is #{onoff ? 'on' : 'off'}\n"
        #else
        #  Byebug.current_context.tracing = onoff
        #  print "Tracing #{onoff ? 'on' : 'off'} on current thread.\n"
        #end
      elsif @match[1] =~ /var(?:iable)?/
        varname=@match[2]
        if debug_eval("defined?(#{varname})")
          if @match[3] && @match[3] !~ /(:?no)?stop/
            errmsg("expecting 'stop' or 'nostop'; got %s\n" % @match[3])
          else
            dbg_cmd = (@match[3] && (@match[3] !~ /nostop/)) ? 'byebug' : ''
          end
          eval("trace_var(:#{varname}) do |val|
                  print \"traced variable \#{varname} has value \#{val}\n\"
                  #{dbg_cmd}
                end")
        else
          errmsg "#{varname} is not a global variable.\n"
        end
      else
        errmsg("expecting 'on', 'off', 'var' or 'variable'; got: %s\n" %
               @match[1])
      end
    end

    class << self
      def help_command
        'trace'
      end

      def help(cmd)
        %{
          tr[ace] (on|off)\tset trace mode of current thread
          tr[ace] (on|off) all\tset trace mode of all threads
          tr[ace] var(iable) VARNAME [stop|nostop]\tset trace variable on VARNAME
        }
      end
    end
  end
end
