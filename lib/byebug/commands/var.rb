require 'byebug/commands/var/all'
require 'byebug/commands/var/const'
require 'byebug/commands/var/instance'
require 'byebug/commands/var/local'
require 'byebug/commands/var/global'

module Byebug
  #
  # Shows variables and its values
  #
  class VarCommand < Command
    def regexp
      /^\s* v(?:ar)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-EOD
        [v]ar <subcommand>

        Shows variables and its values.
      EOD
    end
  end
end
