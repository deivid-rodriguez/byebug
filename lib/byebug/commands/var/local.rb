require 'byebug/helpers/var'

module Byebug
  #
  # Reopens the +var+ command to define the +local+ subcommand
  #
  class VarCommand < Command
    #
    # Shows local variables in current scope
    #
    class LocalSubcommand < Command
      include Helpers::VarHelper

      def regexp
        /^\s* l(?:ocal)? \s*$/x
      end

      def description
        <<-EOD
          v[ar] l[ocal]

          #{short_description}
        EOD
      end

      def short_description
        'Shows local variables in current scope.'
      end

      def execute
        var_local
      end
    end
  end
end
