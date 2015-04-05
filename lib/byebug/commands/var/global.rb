require 'byebug/subcommand'
require 'byebug/helpers/var'

module Byebug
  #
  # Reopens the +var+ command to define the +global+ subcommand
  #
  class VarCommand < Command
    #
    # Shows global variables
    #
    class GlobalSubcommand < Subcommand
      include Helpers::VarHelper

      def regexp
        /^\s* g(?:lobal)? \s*$/x
      end

      def execute
        var_global
      end

      def self.short_description
        'Shows global variables.'
      end

      def self.description
        <<-EOD
          v[ar] g[lobal]

          #{short_description}
        EOD
      end
    end
  end
end
