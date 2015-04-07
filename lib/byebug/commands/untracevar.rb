require 'byebug/command'

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
        untrace_var(:"#{var}")
        puts pr('trace.messages.undo', var: var)
      else
        errmsg pr('trace.errors.not_global', var: var)
      end
    end

    def description
      <<-EOD
        untr[acevar] <variable>

        Stop tracing global variable <variable>.
      EOD
    end
  end
end
