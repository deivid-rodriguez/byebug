require 'byebug/subcommands'

require 'byebug/commands/disable/breakpoints'
require 'byebug/commands/disable/display'

module Byebug
  #
  # Disabling custom display expressions or breakpoints.
  #
  class DisableCommand < Command
    include Subcommands

    def regexp
      /^\s* dis(?:able)? (?:\s+ (.+))? \s*$/x
    end

    def description
      <<-EOD
        dis[able][[ breakpoints| display)][ n1[ n2[ ...[ nn]]]]]

        Disables breakpoints or displays.

        "disable" by itself shows this help
        "disable breakpoints" disables all breakpoints.
        "disable displays" disables all displays.

        You can also specify a space separated list of breakpoint or display
        numbers to disable only specific breakpoints or displays.
       EOD
    end
  end
end
