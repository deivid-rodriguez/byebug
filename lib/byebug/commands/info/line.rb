require 'byebug/subcommand'

module Byebug
  #
  # Reopens the +info+ command to define the +line+ subcommand
  #
  class InfoCommand < Command
    #
    # Information about current location
    #
    class LineSubcommand < Subcommand
      def regexp
        /^\s* l(?:ine)? \s*$/x
      end

      def execute
        puts "Line #{@state.line} of \"#{@state.file}\""
      end

      def self.short_description
        'Line number and file name of current position in source file.'
      end

      def self.description
        <<-EOD
          inf[o] l[ine]

          #{short_description}
        EOD
      end
    end
  end
end
