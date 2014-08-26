module Byebug
  #
  # Processes commands in 'control' mode, when there's no program running
  #
  class ControlCommandProcessor < Processor
    def initialize(interface = LocalInterface.new)
      super(interface)
      @context_was_dead = false # Assume we haven't started.
    end

    def process_commands(verbose = false)
      control_cmds = Command.commands.select do |cmd|
        cmd.allow_in_control
      end
      state = State.new(@interface, control_cmds)
      commands = control_cmds.map { |cmd| cmd.new(state) }

      if @context_was_dead
        puts 'The program finished.'
        @context_was_dead = false
      end

      while (input = @interface.read_command(prompt(nil)))
        puts("+#{input}") if verbose

        cmd = commands.find { |c| c.match(input) }
        return errmsg('Unknown command') unless cmd

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

    class State
      attr_reader :commands, :interface

      def initialize(interface, commands)
        @interface = interface
        @commands = commands
      end

      def proceed
      end

      extend Forwardable
      def_delegators :@interface, :errmsg, :puts

      def confirm(*_args)
        'y'
      end

      def context
        nil
      end

      def file
        errmsg 'No filename given.'
      end
    end
  end
end
