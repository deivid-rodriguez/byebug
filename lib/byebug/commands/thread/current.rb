require 'byebug/helpers/thread'

module Byebug
  #
  # Reopens the +thread+ command to define the +current+ subcommand
  #
  class ThreadCommand < Command
    #
    # Information about the current thread
    #
    class CurrentSubcommand < Command
      include Helpers::ThreadHelper

      def regexp
        /^\s* c(?:urrent)? \s*$/x
      end

      def execute
        display_context(@state.context)
      end

      def short_description
        'Shows current thread information'
      end

      def description
        <<-EOD
          th[read] c[urrent]

          #{short_description}
        EOD
      end
    end
  end
end
