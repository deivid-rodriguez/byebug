require 'byebug/command'

module Byebug
  #
  # Ask for help from byebug's prompt.
  #
  class HelpCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* h(?:elp)? (?: \s+(\S+) (?:\s+(\S+))? )? \s*$/x
    end

    def execute
      return puts(self.class.help) unless @match[1]

      cmd = Command.commands.select { |c| c.names.include?(@match[1]) }
      return errmsg(pr('help.errors.undefined', cmd: @match[1])) unless cmd.any?

      cmd.each { |c| puts c.help(@match[2]) }
    end

    class << self
      def names
        %w(help)
      end

      def description
        prettify <<-EOD
          h[elp][ <cmd>[ <subcmd>]]

          help                -- prints this help.
          help <cmd>          -- prints help on command <cmd>.
          help <cmd> <subcmd> -- prints help on <cmd>'s subcommand <subcmd>.
        EOD
      end
    end
  end
end
