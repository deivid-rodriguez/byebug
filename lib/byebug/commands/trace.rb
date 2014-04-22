module Byebug

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
          dbg_cmd = (@match[2] && @match[2] !~ /nostop/) ? 'byebug(1, false)' : ''
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
        %{tr[acevar] VARNAME [stop|nostop]\tset trace variable on VARNAME}
      end
    end
  end
end
