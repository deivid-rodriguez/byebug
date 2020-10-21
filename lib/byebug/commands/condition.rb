# frozen_string_literal: true

require_relative "../subcommands"

require_relative "condition/expression"
require_relative "condition/hitcount"

module Byebug
  #
  # Implements conditions on breakpoints.
  #
  # Adds the ability to stop on breakpoints only under certain conditions.
  #
  class ConditionCommand < Command
    include Subcommands

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* cond(?:ition)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        cond[ition] <subcommand>

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Sets conditions on breakpoints"
    end

    def execute
      subcmd_name = @match[1]
      return puts(help) unless subcmd_name

      # default to the expression subcommand, for backwards compatability
      subcmd = subcommand_list.match(subcmd_name) || subcommand_list.match('expression')
      subcmd.new(processor, arguments).execute
    end
  end
end
