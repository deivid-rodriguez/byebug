module Byebug
  class ControlCommandProcessor < Processor
    def initialize(interface)
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
        print "The program finished.\n"
        @context_was_dead = false
      end

      while (input = @interface.read_command(prompt(nil)))
        print "+#{input}" if verbose
        catch(:debug_error) do
          cmd = commands.find { |c| c.match(input) }
          return errmsg "Unknown command\n" unless cmd

          cmd.execute
        end
      end
    rescue IOError, SystemCallError
    rescue
      print "INTERNAL ERROR!!! #{$ERROR_INFO}\n" rescue nil
      print $ERROR_INFO.backtrace.map { |l| "\t#{l}" }.join("\n") rescue nil
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
      def_delegators :@interface, :errmsg, :print

      def confirm(*_args)
        'y'
      end

      def context
        nil
      end

      def file
        errmsg "No filename given.\n"
        throw :debug_error
      end
    end
  end
end
