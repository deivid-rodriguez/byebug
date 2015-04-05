require 'byebug/subcommand'
require 'byebug/helpers/var'

module Byebug
  #
  # Reopens the +var+ command to define the +local+ subcommand
  #
  class VarCommand < Command
    #
    # Shows local variables in current scope
    #
    class LocalSubcommand < Subcommand
      include Helpers::VarHelper

      def regexp
        /^\s* l(?:ocal)? \s*$/x
      end

      def execute
        var_local
      end

      def self.short_description
        'Shows local variables in current scope.'
      end

      def self.description
        <<-EOD
          v[ar] l[ocal]

          #{short_description}
        EOD
      end
    end
  end
end
