require 'byebug/subcommand'
require 'byebug/helpers/thread'

module Byebug
  #
  # Reopens the +thread+ command to define the +list+ subcommand
  #
  class ThreadCommand < Command
    #
    # Information about threads
    #
    class ListSubcommand < Subcommand
      include Helpers::ThreadHelper

      def regexp
        /^\s* l(?:ist)? \s*$/x
      end

      def execute
        contexts = Byebug.contexts.sort_by(&:thnum)

        thread_list = prc('thread.context', contexts) do |context, _|
          thread_arguments(context)
        end

        print(thread_list)
      end

      def self.short_description
        'Lists all threads'
      end

      def self.description
        <<-EOD
          th[read] l[ist] <thnum>

          #{short_description}
        EOD
      end
    end
  end
end
