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

        #{short_description}
       EOD
    end

    def short_description
      'Disables breakpoints or displays'
    end
  end
end
