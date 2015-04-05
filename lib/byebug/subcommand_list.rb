module Byebug
  #
  # Holds an array of subcommands for a command
  #
  class SubcommandList
    def initialize(commands, parent)
      @commands = commands
      @parent = parent
    end

    def find(name)
      @commands.find { |cmd| cmd.match(name) }
    end

    def help(name)
      subcmd = find(name)
      return errmsg("Unknown subcommand '#{name}'") unless subcmd

      subcmd.help
    end

    def to_s
      width = @commands.map(&:to_name).max_by(&:size).size

      formatted_cmds = @commands.map do |subcmd|
        format("%s %-#{width}s -- %s\n",
               @parent, subcmd.to_name, subcmd.short_description)
      end

      formatted_cmds.join
    end
  end
end
