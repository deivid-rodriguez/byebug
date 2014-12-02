require 'byebug/states/control_state'

module Byebug
  #
  # Processes commands in 'control' mode, when there's no program running
  #
  class ControlCommandProcessor < Processor
    def initialize(interface = LocalInterface.new)
      super(interface)
      @context_was_dead = false # Assume we haven't started.
    end

    def process_commands
      control_cmds = Command.commands.select(&:allow_in_control)
      state = Byebug::ControlState.new(@interface, control_cmds)
      commands = control_cmds.map { |cmd| cmd.new(state) }

      if @context_was_dead
        puts 'The program finished.'
        @context_was_dead = false
      end

      while (input = @interface.read_command(prompt(nil)))
        cmd = commands.find { |c| c.match(input) }
        unless cmd
          errmsg('Unknown command')
          next
        end

        cmd.execute
      end
    rescue IOError, SystemCallError
    rescue
      without_exceptions do
        puts "INTERNAL ERROR!!! #{$ERROR_INFO}"
        puts $ERROR_INFO.backtrace.map { |l| "\t#{l}" }.join("\n")
      end
    ensure
      @interface.close
    end

    #
    # Prompt shown before reading a command.
    #
    def prompt(_context)
      '(byebug:ctrl) '
    end
  end
end
