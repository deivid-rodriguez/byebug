require 'byebug/command'

module Byebug
  #
  # Ask for help from byebug's prompt.
  #
  class HelpCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* h(?:elp)? (?:\s+(\S+))? (?:\s+(\S+))? \s*$/x
    end

    def execute
      return puts(help) unless @match[1]

      cmd = Byebug.commands.find { |c| c.to_name == @match[1] }
      return errmsg(pr('help.errors.undefined', cmd: @match[1])) unless cmd

      cmd = cmd.new(@state)
      return puts(cmd.help) unless @match[2]

      subcmd = cmd.subcommands.find(@match[2])
      return errmsg(pr('help.errors.undefined', cmd: @match[2])) unless subcmd

      puts(subcmd.help)
    end

    def description
      <<-EOD
        h[elp][ <cmd>[ <subcmd>]]

        help                -- prints this help.
        help <cmd>          -- prints help on command <cmd>.
        help <cmd> <subcmd> -- prints help on <cmd>'s subcommand <subcmd>.
      EOD
    end
  end
end
