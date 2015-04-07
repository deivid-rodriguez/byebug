module Byebug
  #
  # Reopens the +info+ command to define the +breakpoints+ subcommand
  #
  class InfoCommand < Command
    #
    # Information about current breakpoints
    #
    class BreakpointsSubcommand < Command
      def regexp
        /^\s* b(?:reakpoints)? (?:\s+ (.+))? \s*$/x
      end

      def execute
        return puts('No breakpoints.') if Byebug.breakpoints.empty?

        breakpoints = Byebug.breakpoints.sort_by(&:id)

        if @match[1]
          indices = @match[1].split(/ +/).map(&:to_i)
          breakpoints = breakpoints.select { |b| indices.member?(b.id) }
          if breakpoints.empty?
            return errmsg('No breakpoints found among list given')
          end
        end

        puts 'Num Enb What'
        breakpoints.each { |b| info_breakpoint(b) }
      end

      def short_description
        'Status of user settable breakpoints.'
      end

      def description
        <<-EOD
          inf[o] b[reakpoints]

          #{short_description}
        EOD
      end

      private

      def info_breakpoint(brkpt)
        expr = brkpt.expr.nil? ? '' : " if #{brkpt.expr}"
        y_n = brkpt.enabled? ? 'y' : 'n'
        interp = format('%-3d %-3s at %s:%s%s',
                        brkpt.id, y_n, brkpt.source, brkpt.pos, expr)
        puts interp
        hits = brkpt.hit_count
        return unless hits > 0

        s = (hits > 1) ? 's' : ''
        puts "\tbreakpoint already hit #{hits} time#{s}"
      end
    end
  end
end
