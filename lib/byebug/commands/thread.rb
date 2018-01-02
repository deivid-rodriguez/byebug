# frozen_string_literal: true

require "byebug/subcommands"

require "byebug/commands/thread/current"
require "byebug/commands/thread/list"
require "byebug/commands/thread/resume"
require "byebug/commands/thread/stop"
require "byebug/commands/thread/switch"

module Byebug
  #
  # Manipulation of Ruby threads
  #
  class ThreadCommand < Command
    include Subcommands

    def self.regexp
      /^\s* th(?:read)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        th[read] <subcommand>

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Commands to manipulate threads"
    end
  end
end
