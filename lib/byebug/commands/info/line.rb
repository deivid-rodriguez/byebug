module Byebug
  #
  # Reopens the +info+ command to define the +line+ subcommand
  #
  class InfoCommand < Command
    #
    # Information about current location
    #
    class LineSubcommand < Command
      self.allow_in_post_mortem = true

      def regexp
        /^\s* l(?:ine)? \s*$/x
      end

      def description
        <<-EOD
          inf[o] l[ine]

          #{short_description}
        EOD
      end

      def short_description
        'Line number and file name of current position in source file.'
      end

      def execute
        puts "Line #{@state.line} of \"#{@state.file}\""
      end
    end
  end
end
