module Byebug
  class HistoryCommand < Command
    def regexp
      /^\s* hist(?:ory)? (?:\s+(?<num_cmds>.+))? \s*$/x
    end

    def execute
      if Setting[:autosave]
        if arg = @match[:num_cmds]
          size = get_int(arg, 'history', 1, Setting[:histsize])
        end
        print History.to_s(size || Setting[:histsize])
      else
        errmsg "Not currently saving history. Enable it with \"set autosave\"\n"
      end
    end

    class << self
      def names
        %w(history)
      end

      def description
        %{hist[ory] [num_cmds]\t\tShow byebug's command history}
      end
    end
  end
end
