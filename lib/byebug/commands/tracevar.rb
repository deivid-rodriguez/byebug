module Byebug
  #
  # Show (and possibily stop) at every line that changes a global variable.
  #
  class TracevarCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* tr(?:acevar)? (?: \s+ (\S+))?  # (variable-name)?
                          (?: \s+ (\S+))?  # (stop | nostop)?
       \s*$/x
    end

    def execute
      var = @match[1]
      return errmsg('tracevar needs a global variable name') unless var

      unless global_variables.include?(:"#{var}")
        return errmsg("'#{var}' is not a global variable.")
      end

      if @match[2] && @match[2] !~ /(:?no)?stop/
        return errmsg("expecting 'stop' or 'nostop'; got '#{@match[2]}'")
      end

      stop = @match[2] && @match[2] !~ /nostop/

      instance_eval do
        trace_var(:"#{var}") { |val| on_change(var, val, stop) }
      end

      puts "Tracing global variable \"#{var}\"."
    end

    def on_change(name, value, stop)
      puts "traced global variable '#{name}' has value '#{value}'"
      byebug(1, false) if stop
    end

    class << self
      def names
        %w(tracevar)
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
