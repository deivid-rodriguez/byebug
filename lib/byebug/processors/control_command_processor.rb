require 'byebug/states/control_state'

module Byebug
  #
  # Processes commands in 'control' mode, when there's no program running
  #
  class ControlCommandProcessor < Processor
    attr_reader :state

    def initialize(interface = LocalInterface.new)
      super(interface)
    end

    def commands
      Byebug.commands.select(&:allow_in_control).map { |cmd| cmd.new(state) }
    end

    def process_commands
      @state = ControlState.new(interface)

      while (input = @interface.read_command(prompt(nil)))
        cmd = commands.find { |c| c.match(input) }
        unless cmd
          errmsg('Unknown command')
          next
        end

        cmd.execute
      end

      @interface.close
    rescue IOError, SystemCallError
      @interface.close
    rescue
      without_exceptions do
        puts "INTERNAL ERROR!!! #{$ERROR_INFO}"
        puts $ERROR_INFO.backtrace.map { |l| "\t#{l}" }.join("\n")
      end
    end

    #
    # Prompt shown before reading a command.
    #
    def prompt(_context)
      '(byebug:ctrl) '
    end
  end
end
