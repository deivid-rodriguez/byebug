module Byebug
  #
  # Reopens the +var+ command to define the +global+ subcommand
  #
  class VarCommand < Command
    #
    # Shows global variables
    #
    class GlobalSubcommand < Command
      include Helpers::VarHelper

      def regexp
        /^\s* g(?:lobal)? \s*$/x
      end

      def execute
        var_global
      end

      def short_description
        'Shows global variables.'
      end

      def description
        <<-EOD
          v[ar] g[lobal]

          #{short_description}
        EOD
      end
    end
  end
end
