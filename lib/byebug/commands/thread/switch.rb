require 'byebug/helpers/thread'

module Byebug
  #
  # Reopens the +thread+ command to define the +switch+ subcommand
  #
  class ThreadCommand < Command
    #
    # Switches to the specified thread
    #
    class SwitchSubcommand < Command
      include Helpers::ThreadHelper

      def regexp
        /^\s* sw(?:itch)? (?: \s* (\d+))? \s*$/x
      end

      def execute
        return puts(help) unless @match[1]

        context, err = context_from_thread(@match[1])
        return errmsg(err) if err

        display_context(context)

        context.switch
        @state.proceed
      end

      def short_description
        'Switches execution to the specified thread'
      end

      def description
        <<-EOD
          th[read] sw[itch] <thnum>

          #{short_description}
        EOD
      end
    end
  end
end
