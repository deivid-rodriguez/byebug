require 'byebug/command'
require 'byebug/helpers/parse'

module Byebug
  #
  # Implements the continue always command.
  #
  # Allows the user to continue execution and
  # ignore all next breakpoints
  #
  class ContinueAlwaysCommand < Command
    include Helpers::ParseHelper

    def self.regexp
      /^\s* c(?:ont(?:inue)?_)?(?:a(?:lways)?) \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        c[ont[inue]_]a[lways]
        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      'Runs the command and ignore all next breakpoints'
    end

    def execute
      self.class.always_run = 2
      processor.proceed!

      ListCommand.always_run = 0
      Byebug.stop if Byebug.stoppable?
    end
  end
end
