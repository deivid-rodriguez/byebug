require 'byebug/subcommand'
require 'byebug/helpers/thread'

module Byebug
  #
  # Reopens the +thread+ command to define the +current+ subcommand
  #
  class ThreadCommand < Command
    #
    # Information about the current thread
    #
    class CurrentSubcommand < Subcommand
      include Helpers::ThreadHelper

      def regexp
        /^\s* c(?:urrent)? \s*$/x
      end

      def execute
        display_context(@state.context)
      end

      def self.short_description
        'Shows current thread information'
      end

      def self.description
        <<-EOD
          th[read] c[urrent]

          #{short_description}
        EOD
      end
    end
  end
end
