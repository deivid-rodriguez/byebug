require 'byebug/helpers/toggle'

module Byebug
  #
  # Reopens the +disable+ command to define the +breakpoints+ subcommand
  #
  class DisableCommand < Command
    #
    # Disables all or specific breakpoints
    #
    class BreakpointsSubcommand < Command
      include Helpers::ToggleHelper

      def regexp
        /^\s* b(?:reakpoints)? (?:\s+ (.+))? \s*$/x
      end

      def execute
        enable_disable_breakpoints('disable', @match[1])
      end

      def short_description
        'Disable all or specific breakpoints.'
      end

      def description
        <<-EOD
          dis[able] b[reakpoints][ <id1> <id2> .. <idn>]

          #{short_description}

          Give breakpoint numbers (separated by spaces) as arguments or no
          argument at all if you want to disable every breakpoint.
        EOD
      end
    end
  end
end
