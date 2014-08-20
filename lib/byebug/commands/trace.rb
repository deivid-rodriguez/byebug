module Byebug
  #
  # Show information about every line that is executed.
  #
  class TraceCommand < Command
    def regexp
      /^\s* tr(?:acevar)? (?: \s+ (\S+))?  # (variable-name)?
                          (?: \s+ (\S+))?  # (stop | nostop)?
       \s*$/x
    end

    def execute
      varname = @match[1]
      if global_variables.include?("$#{varname}".to_sym)
        if @match[2] && @match[2] !~ /(:?no)?stop/
          errmsg "expecting \"stop\" or \"nostop\"; got \"#{@match[2]}\"\n"
        else
          dbg_cmd = if @match[2] && @match[2] !~ /nostop/
                      'byebug(1, false)'
                    else
                      ''
                    end
        end
        eval("trace_var(:\"\$#{varname}\") do |val|
                print \"traced global variable '#{varname}' has value '\#{val}'\"\n
                #{dbg_cmd}
              end")
        print "Tracing global variable \"#{varname}\".\n"
      else
        errmsg "'#{varname}' is not a global variable.\n"
      end
    end

    class << self
      def names
        %w(trace)
      end

      def description
        %(tr[acevar] <variable> [[no]stop]

          Start tracing variable <variable>.

          If "stop" is specified, execution will stop every time the variable
          changes its value. If nothing or "nostop" is specified, execution
          won't stop, changes will just be logged in byebug's output.)
      end
    end
  end
end
