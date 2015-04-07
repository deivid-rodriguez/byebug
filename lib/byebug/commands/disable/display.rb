require 'byebug/helpers/toggle'

module Byebug
  #
  # Reopens the +disable+ command to define the +display+ subcommand
  #
  class DisableCommand < Command
    #
    # Enables all or specific displays
    #
    class DisplaySubcommand < Command
      include Helpers::ToggleHelper

      def regexp
        /^\s* d(?:isplay)? (?:\s+ (.+))? \s*$/x
      end

      def execute
        enable_disable_display('disable', @match[1])
      end

      def short_description
        'Disables expressions to be displayed when program stops.'
      end

      def description
        <<-EOD
          dis[able] d[isplay][ <id1> <id2> .. <idn>]

          #{short_description}

          Arguments are the code numbers of the expressions to disable. Do "info
          display" to see the current list of code numbers. If no arguments are
          specified, all displays are disabled.
        EOD
      end
    end
  end
end
