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
      var = @match[1]
      if global_variables.include?("$#{var}".to_sym)
        if @match[2] && @match[2] !~ /(:?no)?stop/
          errmsg "expecting \"stop\" or \"nostop\"; got \"#{@match[2]}\""
        else
          dbg_cmd = if @match[2] && @match[2] !~ /nostop/
                      'byebug(1, false)'
                    else
                      ''
                    end
        end
        eval("trace_var(:\"\$#{var}\") do |val|
                puts \"traced global variable '#{var}' has value '\#{val}'\"
                #{dbg_cmd}
              end")
        puts "Tracing global variable \"#{var}\"."
      else
        errmsg "'#{var}' is not a global variable."
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
