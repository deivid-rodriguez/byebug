require 'byebug/helpers/toggle'

module Byebug
  #
  # Reopens the +enable+ command to define the +breakpoints+ subcommand
  #
  class EnableCommand < Command
    #
    # Enables all or specific breakpoints
    #
    class BreakpointsSubcommand < Command
      include Helpers::ToggleHelper

      def regexp
        /^\s* b(?:reakpoints)? (?:\s+ (.+))? \s*$/x
      end

      def execute
        enable_disable_breakpoints('enable', @match[1])
      end

      def short_description
        'Disable all or specific breakpoints'
      end

      def description
        <<-EOD
          en[able] b[reakpoints][ <ids>]

          #{short_description}

          Give breakpoint numbers (separated by spaces) as arguments or no
          argument at all if you want to enable every breakpoint.
        EOD
      end
    end
  end
end
