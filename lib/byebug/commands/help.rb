module Byebug
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
          errmsg "Undefined command: \"#{args[0]}\". Try \"help\"\n" if args[0]
        else
          help = cmds.map { |cmd| cmd.help(args) }.join("\n")
          help = help.split("\n").map { |l| l.gsub(/^ +/, '') }
          help.shift if help.first && help.first.empty?
          help.pop if help.last && help.last.empty?
          print help.join("\n") + "\n"
        end
      end

      print "byebug help v#{VERSION}\n" unless Setting[:testing]

      print "Type \"help <command-name>\" for help on a specific command\n\n"
      print "Available commands:\n"
      cmds = @state.commands.map { |cmd| cmd.names }.flatten.uniq.sort
      print columnize(cmds, Setting[:width])
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
