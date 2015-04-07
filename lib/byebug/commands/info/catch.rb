module Byebug
  #
  # Reopens the +info+ command to define the +catch+ subcommand
  #
  class InfoCommand < Command
    #
    # Information on exceptions that can be caught by the debugger
    #
    class CatchSubcommand < Command
      def regexp
        /^\s* c(?:atch)? (?:\s+ (.+))? \s*$/x
      end

      def execute
        return puts('No frame selected.') unless @state.context

        if Byebug.catchpoints && !Byebug.catchpoints.empty?
          Byebug.catchpoints.each do |exception, _hits|
            puts("#{exception}: #{exception.is_a?(Class)}")
          end
        else
          puts 'No exceptions set to be caught.'
        end
      end

      def short_description
        'Exceptions that can be caught in the current stack frame'
      end

      def description
        <<-EOD
          inf[o] c[atch]

          #{short_description}
        EOD
      end
    end
  end
end
