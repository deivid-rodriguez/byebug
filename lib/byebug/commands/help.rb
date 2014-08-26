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
      if @match[1]
        args = @match[1].split
        cmds = @state.commands.select { |cmd| cmd.names.include?(args[0]) }
        if cmds.empty?
          return errmsg("Undefined command: \"#{args[0]}\". Try \"help\"")
        end

        return puts(cmds.map { |cmd| cmd.help(args[1..-1]) }.join("\n"))
      end

      puts "byebug help v#{VERSION}" unless Setting[:testing]
      puts "Type \"help <command-name>\" for help on a specific command\n"
      puts 'Available commands:'
      cmds = @state.commands.map { |cmd| cmd.names }.flatten.uniq.sort
      puts columnize(cmds, Setting[:width])
    end

    class << self
      def names
        %w(help)
      end

      def description
        %(h[elp][ <command>[ <subcommand>]]

          "help" alone prints this help.
          "help <command>" prints help on <command>.
          "help <command> <subcommand> prints help on <subcommand>.)
      end
    end
  end
end
