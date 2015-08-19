require 'forwardable'

require 'byebug/helpers/reflection'
require 'byebug/command_list'

module Byebug
  #
  # Subcommand additions.
  #
  module Subcommands
    def self.included(command)
      command.extend(ClassMethods)
    end

    extend Forwardable
    def_delegators :'self.class', :subcommand_list

    #
    # Delegates to subcommands or prints help if no subcommand specified.
    #
    def execute
      return puts(help) unless @match[1]

      subcmd = subcommand_list.match(@match[1])
      fail CommandNotFound.new(@match[1], self.class) unless subcmd

      subcmd.new(processor, arguments).execute
    rescue => e
      errmsg(e.message)
    end

    #
    # Class methods added to subcommands
    #
    module ClassMethods
      include Helpers::ReflectionHelper

      #
      # Default help text for a command with subcommands
      #
      def help
        super + subcommand_list.to_s
      end

      #
      # Command's subcommands.
      #
      def subcommand_list
        @subcommand_list ||= CommandList.new(commands)
      end
    end
  end
end
