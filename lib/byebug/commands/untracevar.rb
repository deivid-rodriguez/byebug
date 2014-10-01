module Byebug
  #
  # Stop tracing a global variable.
  #
  class UntracevarCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* untr(?:acevar)? (?:\s+ (\S+))? \s*$/x
    end

    def execute
      var = @match[1]
      if global_variables.include?(:"#{var}")
        eval("untrace_var(:\"#{var}\")")
        puts "Not tracing global variable \"#{var}\" anymore."
      else
        errmsg "'#{var}' is not a global variable."
      end
    end

    class << self
      def names
        %w(untracevar)
      end

      def description
        %(untr[acevar] <variable>

          Stop tracing global variable <variable>.)
      end
    end
  end
end
