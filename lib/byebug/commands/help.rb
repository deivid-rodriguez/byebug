module Byebug
  #
  # Ask for help from byebug's prompt.
  #
  class HelpCommand < Command
    include Columnize

    self.allow_in_control = true

    def regexp
      /^\s* h(?:elp)? (?:\s+(.+))? \s*$/x
    end

    def execute
      return puts(self.class.help) unless @match[1]

      args = @match[1].split
      cmds = @state.commands.select { |cmd| cmd.names.include?(args[0]) }
      if cmds.empty?
        return errmsg("Undefined command: \"#{args[0]}\". Try \"help\"")
      end

      puts(cmds.map { |cmd| cmd.help(args[1..-1]) }.join("\n"))
    end

    class << self
      def names
        %w(help)
      end

      def description
        <<-EOD.gsub(/^ {8}/, '')
          h[elp][ <command>[ <subcommand>]]

          "help" alone prints this help.
          "help <command>" prints help on <command>.
          "help <command> <subcommand>" prints help on <subcommand>.
        EOD
      end
    end
  end
end
