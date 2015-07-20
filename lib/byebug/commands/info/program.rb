module Byebug
  #
  # Reopens the +info+ command to define the +args+ subcommand
  #
  class InfoCommand < Command
    #
    # Information about arguments of the current method/block
    #
    class ProgramSubcommand < Command
      self.allow_in_post_mortem = true

      def regexp
        /^\s* p(?:rogram)? \s*$/x
      end

      def description
        <<-EOD
          inf[o] p[rogram]

          #{short_description}
        EOD
      end

      def short_description
        'Information about the current status of the debugged program.'
      end

      def execute
        if @state.context.dead?
          puts 'The program crashed.'
          excpt = Byebug.raised_exception
          return puts("Exception: #{excpt.inspect}") if excpt
        end

        puts 'Program stopped. '
        format_stop_reason @state.context.stop_reason
      end

      private

      def format_stop_reason(stop_reason)
        case stop_reason
        when :step
          puts "It stopped after stepping, next'ing or initial start."
        when :breakpoint
          puts 'It stopped at a breakpoint.'
        when :catchpoint
          puts 'It stopped at a catchpoint.'
        end
      end
    end
  end
end
