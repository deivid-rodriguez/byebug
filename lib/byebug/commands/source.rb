module Byebug
  # Implements byebug "source" command.
  class SourceCommand < Command
    self.allow_in_control = true
    
    def regexp
      /^\s* so(?:urce)? \s+ (.+) $/x
    end
    
    def execute
      file = File.expand_path(@match[1]).strip
      unless File.exist?(file)
        errmsg "Command file '#{file}' is not found\n"
        return
      end
      if @state and @state.interface
        @state.interface.command_queue += File.open(file).readlines
      else
        Byebug.run_script(file, @state)
      end
    end
    
    class << self
      def help_command
        'source'
      end
      
      def help(cmd)
        %{
          source FILE\texecutes a file containing byebug commands
        }
      end
    end
  end
  
end
