require 'byebug/subcommands'

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
    include Subcommands

    def regexp
      /^\s* th(?:read)? (?:\s+ (.+))? \s*$/x
    end

    def description
      <<-EOD
        th[read] <subcommand>

        #{short_description}
      EOD
    end

    def short_description
      'Commands to manipulate threads'
    end
  end
end
