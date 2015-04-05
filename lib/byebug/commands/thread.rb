require 'byebug/commands/thread/current'
require 'byebug/commands/thread/list'
require 'byebug/commands/thread/resume'
require 'byebug/commands/thread/stop'
require 'byebug/commands/thread/switch'

module Byebug
  #
  # Manipulation of Ruby threads
  #
  class ThreadCommand < Command
    def regexp
      /^\s* th(?:read)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-EOD
        th]read <subcommand>

        Commands to manipulate threads.
      EOD
    end
  end
end
