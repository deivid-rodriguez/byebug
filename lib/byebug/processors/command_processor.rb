require 'forwardable'

require 'byebug/helpers/eval'
require 'byebug/errors'

module Byebug
  #
  # Processes commands in regular mode.
  #
  # You can override this class to create your own command processor that, for
  # example, whitelists only certain commands to be executed.
  #
  # @see PostMortemProcessor for a example
  #
  class CommandProcessor
    include Helpers::EvalHelper

    attr_accessor :prev_line
    attr_reader :context

    def initialize(context)
      @context = context

      @proceed = false
      @prev_line = nil
    end

    def interface
      @interface ||= context.class.interface
    end

    def printer
      @printer ||= Printers::Plain.new
    end

    def frame
      @context.frame
    end

    extend Forwardable
    def_delegator :printer, :print, :pr
    def_delegator :printer, :print_collection, :prc
    def_delegator :printer, :print_variables, :prv

    def_delegators :interface, :errmsg, :puts, :confirm

    #
    # Available commands
    #
    def command_list
      @command_list ||= CommandList.new(commands)
    end

    def commands
      Byebug.commands
    end

    def at_breakpoint(brkpt)
      number = Byebug.breakpoints.index(brkpt) + 1

      puts "Stopped by breakpoint #{number} at #{frame.file}:#{frame.line}"
    end

    def at_catchpoint(exception)
      puts "Catchpoint at #{context.location}: `#{exception}'"
    end

    def at_tracing
      puts "Tracing: #{context.full_location}"

      run_auto_commands(2)
    end

    def at_line
      process_commands
    end

    def at_return
      process_commands
    end

    #
    # Let the execution continue
    #
    def proceed!
      @proceed = true
    end

    #
    # Handle byebug commands.
    #
    def process_commands
      before_repl

      repl
    ensure
      after_repl
    end

    protected

    #
    # Prompt shown before reading a command.
    #
    def prompt
      '(byebug) '
    end

    private

    def auto_commands_for(run_level)
      command_list.select { |cmd| cmd.always_run >= run_level }
    end

    #
    # Run permanent commands.
    #
    def run_auto_commands(run_level)
      auto_commands_for(run_level).each { |cmd| cmd.new(self).execute }
    end

    def before_repl
      @proceed = false
      @prev_line = nil

      run_auto_commands(1)
      interface.autorestore
    end

    def after_repl
      interface.autosave
    end

    #
    # Main byebug's REPL
    #
    def repl
      until @proceed
        cmd = interface.read_command(prompt)
        return if cmd.nil?

        next if cmd == ''

        run_cmd(cmd)
      end
    end

    #
    # Executes the received input
    #
    # Instantiates a command matching the input and runs it. If a matching
    # command is not found, it evaluates the unknown input.
    #
    def run_cmd(input)
      command = command_list.match(input)
      return command.new(self, input).execute if command

      puts thread_safe_eval(input)
    rescue => e
      errmsg(e.message)
    end
  end
end
