module Byebug
  #
  # Show history of byebug commands.
  #
  class HistoryCommand < Command
    def regexp
      /^\s* hist(?:ory)? (?:\s+(?<num_cmds>.+))? \s*$/x
    end

    def execute
      unless Setting[:autosave]
        return errmsg('Not currently saving history. ' \
                      "Enable it with \"set autosave\"")
      end

      if @match[:num_cmds]
        size, err = get_int(@match[:num_cmds], 'history', 1, Setting[:histsize])
        return errmsg(err) unless size
      end

      puts History.to_s(size || Setting[:histsize])
    end

    class << self
      def names
        %w(history)
      end

      def description
        %(hist[ory] [num_cmds]        Show byebug's command history.)
      end
    end
  end
end
