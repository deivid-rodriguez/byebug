require 'byebug/command'
require 'byebug/subcommand_list'

module Byebug
  #
  # Subcommand additions.
  #
  module Subcommands
    #
    # Summarized description of a subcommand
    #
    def short_description
      fail(NotImplementedError, 'Your custom subcommand needs to define this')
    end

    #
    # Delegates to subcommands or prints help if no subcommand specified.
    #
    def execute
      return puts(help) unless @match[1]

      subcmd = subcommands.find(@match[1])
      return errmsg("Unknown subcommand '#{@match[1]}'\n") unless subcmd

      subcmd.execute
    end

    #
    # Default help text for a command with subcommands
    #
    def help
      prettify <<-EOH
        #{description}

        List of "#{to_name}" subcommands:

        --
        #{subcommands}
      EOH
    end

    #
    # Command's subcommands.
    #
    def subcommands
      subcmd_klasses = self.class.subcommands
      return nil unless subcmd_klasses.any?

      subcmd_list = subcmd_klasses.map { |cmd| cmd.new(@state) }
      SubcommandList.new(subcmd_list, self.class.name)
    end
  end
end
