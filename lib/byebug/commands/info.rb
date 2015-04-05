require 'byebug/commands/info/args'
require 'byebug/commands/info/breakpoints'
require 'byebug/commands/info/catch'
require 'byebug/commands/info/display'
require 'byebug/commands/info/file'
require 'byebug/commands/info/line'
require 'byebug/commands/info/program'

module Byebug
  #
  # Shows info about different aspects of the debugger.
  #
  class InfoCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* i(?:nfo)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-EOD
        info[ subcommand]

        Generic command for showing things about the program being debugged.
      EOD
    end
  end
end
