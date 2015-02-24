require 'byebug/command'

module Byebug
  #
  # Execute a file containing byebug commands.
  #
  # It can be used to restore a previously saved debugging session.
  #
  class SourceCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* so(?:urce)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      return puts(self.class.help) if self.class.names.include?(@match[0])

      unless @state && @state.interface
        return errmsg(pr('source.errors.not_available'))
      end

      file = File.expand_path(@match[1]).strip
      unless File.exist?(file)
        return errmsg(pr('source.errors.not_found', file: file))
      end

      @state.interface.read_file(file)
    end

    class << self
      def names
        %w(source)
      end

      def description
        prettify <<-EOD
          source <file>

          Executes file <file> containing byebug commands.
        EOD
      end
    end
  end
end
