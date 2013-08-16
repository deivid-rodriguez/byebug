module Byebug

  # Implements byebug "source" command.
  class SourceCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* so(?:urce)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      return print SourceCommand.help(nil) if
        SourceCommand.names.include?(@match[0])

      file = File.expand_path(@match[1]).strip
      return errmsg "File \"#{file}\" not found\n" unless File.exist?(file)

      if @state and @state.interface
        @state.interface.command_queue += File.open(file).readlines
      else
        Byebug.run_script(file, @state)
      end
    end

    class << self
      def names
        %w(source)
      end

      def description
        %{source FILE\texecutes a file containing byebug commands}
      end
    end
  end

end
