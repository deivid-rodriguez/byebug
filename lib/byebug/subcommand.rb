require 'byebug/command'

module Byebug
  #
  # Defines a subcommand.
  #
  # It's just like a command, but needs to define a `short_description` (used
  # by the parent command to display its help text).
  #
  class Subcommand < Command
    def_delegators :'self.class', :short_description

    #
    # Summarized description of a subcommand
    #
    def self.short_description
      fail(NotImplementedError, 'Your custom subcommand needs to define this')
    end
  end
end
