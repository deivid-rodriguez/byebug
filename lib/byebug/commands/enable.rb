require 'byebug/commands/enable/breakpoints'
require 'byebug/commands/enable/display'

module Byebug
  #
  # Enabling custom display expressions or breakpoints.
  #
  class EnableCommand < Command
    def regexp
      /^\s* en(?:able)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-EOD
        en[able][[ b[reakpoints]| d[isplay])][ n1[ n2[ ...[ nn]]]]]

        Enables breakpoints or displays.
      EOD
    end
  end
end
