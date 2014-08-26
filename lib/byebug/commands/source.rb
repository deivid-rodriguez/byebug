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

      file = File.expand_path(@match[1]).strip
      return errmsg("File \"#{file}\" not found") unless File.exist?(file)

      if @state && @state.interface
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
        %(source <file>

          Executes file <file> containing byebug commands.)
      end
    end
  end
end
