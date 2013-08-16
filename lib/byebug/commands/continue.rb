module Byebug

  # Implements byebug "continue" command.
  class ContinueCommand < Command
    self.allow_in_post_mortem = true
    self.need_context         = false

    def regexp
      /^\s* c(?:ont(?:inue)?)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      if @match[1] && !@state.context.dead?
        filename = File.expand_path(@state.file)
        return unless line_number = get_int(@match[1], "Continue", 0, nil, 0)
        return errmsg "Line #{line_number} is not a stopping point in file " \
                      "\"#{filename}\"\n" unless
          LineCache.trace_line_numbers(filename).member?(line_number)

        Byebug.add_breakpoint filename, line_number
      end
      @state.proceed
    end

    class << self
      def names
        %w(continue)
      end

      def description
        %{c[ont[inue]][ nnn]

          Run until program ends, hits a breakpoint or reaches line nnn}
      end
    end
  end
end
