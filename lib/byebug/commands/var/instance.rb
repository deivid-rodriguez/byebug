require 'byebug/subcommand'
require 'byebug/helpers/var'

module Byebug
  #
  # Reopens the +var+ command to define the +instance+ subcommand
  #
  class VarCommand < Command
    #
    # Shows instance variables
    #
    class InstanceSubcommand < Subcommand
      include Helpers::VarHelper

      def regexp
        /^\s* i(?:nstance)? (?:\s+ (.+))? \s*$/x
      end

      def execute
        var_instance(@match[1])
      end

      def self.short_description
        'Shows instance variables of self or a specific object.'
      end

      def self.description
        <<-EOD
          v[ar] i[nstance][ <object>]

          #{short_description}
        EOD
      end
    end
  end
end
