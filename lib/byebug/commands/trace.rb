module Byebug

  class TraceCommand < Command
    def regexp
      /^\s* tr(?:ace)? (?: \s+ (\S+))   # on | off | var(iable)
                       (?: \s+ (\S+))?  # (variable-name)?
                       (?: \s+ (\S+))?  # (stop | nostop)?
       \s*$/x
    end

    def execute
      if @match[1] =~ /on|off/
        onoff = 'on' == @match[1]
        Byebug.tracing = onoff
        print "#{show_setting('linetrace')}\n"
      elsif @match[1] =~ /var(?:iable)?/
        varname = @match[2]
        if global_variables.include?("$#{varname}".to_sym)
          if @match[3] && @match[3] !~ /(:?no)?stop/
            errmsg "expecting \"stop\" or \"nostop\"; got \"#{@match[3]}\"\n"
          else
            dbg_cmd = (@match[3] && @match[3] !~ /nostop/) ? 'byebug(1,0)' : ''
          end
          eval("trace_var(:\"\$#{varname}\") do |val|
                  print \"traced global variable '#{varname}' has value '\#{val}'\"\n
                  #{dbg_cmd}
                end")
          print "Tracing global variable \"#{varname}\".\n"
        else
          errmsg "'#{varname}' is not a global variable.\n"
        end
      else
        errmsg "expecting \"on\", \"off\", \"var\" or \"variable\"; got: " \
               "\"#{@match[1]}\"\n"
      end
    end

    class << self
      def names
        %w(trace)
      end

      def description
        %{tr[ace] (on|off)\tset trace mode
          tr[ace] var(iable) VARNAME [stop|nostop]\tset trace variable on VARNAME}
      end
    end
  end
end
