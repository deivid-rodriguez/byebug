require 'byebug/states/regular_state'

module Byebug
  #
  # Processes commands in regular mode
  #
  class CommandProcessor < Processor
    attr_reader :display, :state

    def initialize(interface = LocalInterface.new)
      super(interface)

      @display = []
      @last_cmd = nil # To allow empty (just <RET>) commands
      @context_was_dead = false # Assume we haven't started.
    end

    def interface=(interface)
      @interface.close if @interface
      @interface = interface
    end

    include FileFunctions

    def at_breakpoint(_context, breakpoint)
      n = Byebug.breakpoints.index(breakpoint) + 1
      file = normalize(breakpoint.source)
      line = breakpoint.pos

      puts "Stopped by breakpoint #{n} at #{file}:#{line}"
    end

    def at_catchpoint(context, excpt)
      file = normalize(context.frame_file(0))
      line = context.frame_line(0)

      puts "Catchpoint at #{file}:#{line}: `#{excpt}' (#{excpt.class})"
    end

    def at_tracing(context, file, line)
      puts "Tracing: #{normalize(file)}:#{line} #{get_line(file, line)}"

      always_run(context, file, line, 2)
    end

    def at_line(context, file, line)
      process_commands(context, file, line)
    end

    def at_return(context, file, line)
      process_commands(context, file, line)
    end

    private

    #
    # Prompt shown before reading a command.
    #
    def prompt(context)
      "(byebug#{context.dead? ? ':post-mortem' : ''}) "
    end

    #
    # Run commands everytime.
    #
    # For example display commands or possibly the list or irb in an "autolist"
    # or "autoirb".
    #
    # @return List of commands acceptable to run bound to the current state
    #
    def always_run(context, file, line, run_level)
      @state = RegularState.new(context, @display, file, @interface, line)

      # Change default when in irb or code included in command line
      Setting[:autolist] = false if ['(irb)', '-e'].include?(file)

      # Bind commands to the current state.
      Command.commands.each do |cmd|
        cmd.new(state).execute if cmd.always_run >= run_level
      end
    end

    #
    # Handle byebug commands.
    #
    def process_commands(context, file, line)
      always_run(context, file, line, 1)

      puts 'The program finished.' if program_just_finished?(context)
      puts(state.location) if Setting[:autolist] == 0

      @interface.autorestore

      repl(context)
    ensure
      @interface.autosave
    end

    #
    # Main byebug's REPL
    #
    def repl(context)
      until state.proceed?
        cmd = @interface.read_command(prompt(context))
        return unless cmd

        next if cmd == '' && @last_cmd.nil?

        cmd.empty? ? cmd = @last_cmd : @last_cmd = cmd

        one_cmd(context, cmd)
      end
    end

    #
    # Autoevals a single command
    #
    def one_unknown_cmd(input)
      unless Setting[:autoeval]
        return errmsg("Unknown command: \"#{input}\". Try \"help\"")
      end

      eval_cmd = EvalCommand.new(state)
      eval_cmd.match(input)
      eval_cmd.execute
    end

    #
    #
    # Executes a single byebug command
    #
    def one_cmd(context, input)
      cmd = match_cmd(input)

      return one_unknown_cmd(input) unless cmd

      if context.dead? && !cmd.class.allow_in_post_mortem
        return errmsg('Command unavailable in post mortem mode.')
      end

      cmd.execute
    end

    #
    # Finds a matches the command matching the input
    #
    def match_cmd(input)
      Command.commands.each do |c|
        cmd = c.new(state)
        return cmd if cmd.match(input)
      end

      nil
    end

    #
    # Returns true first time control is given to the user after program
    # termination.
    #
    def program_just_finished?(context)
      result = context.dead? && !@context_was_dead
      @context_was_dead = false if result == true
      result
    end
  end
end
