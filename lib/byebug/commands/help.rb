module Byebug

  # Implements byebug "help" command.
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
        unless cmds.empty?
          help = cmds.map{ |cmd| cmd.help(args) }.join("\n")
          help = help.split("\n").map{|l| l.gsub(/^ +/, '')}
          help.shift if help.first && help.first.empty?
          help.pop if help.last && help.last.empty?
          return print help.join("\n") + "\n"
        else
          return errmsg "Undefined command: \"#{args[0]}\".  Try \"help\".\n" if
            args[0]
        end
      end

      print "byebug help v#{Byebug::VERSION}\n" unless
        Command.settings[:testing]

      print "Type \"help <command-name>\" for help on a specific command\n\n"
      print "Available commands:\n"
      cmds = @state.commands.map{ |cmd| cmd.names }.flatten.uniq.sort
      print columnize(cmds, Command.settings[:width])
    end

    class << self
      def names
        %w(help)
      end

      def description
        %{h[elp]\t\tprint this help
          h[elp] command\tprint help on command
          h[elp] command subcommand\tprint help on subcommand}
      end
    end
  end
end
