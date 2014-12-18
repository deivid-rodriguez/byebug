require 'byebug/states/regular_state'

module Byebug
  #
  # Processes commands in regular mode
  #
  class CommandProcessor < Processor
    attr_reader :display

    def initialize(interface = LocalInterface.new)
      super(interface)

      @display = []
      @mutex = Mutex.new
      @last_cmd = nil # To allow empty (just <RET>) commands
      @last_file = nil # Filename the last time we stopped
      @last_line = nil # Line number the last time we stopped
      @context_was_dead = false # Assume we haven't started.
    end

    def interface=(interface)
      @mutex.synchronize do
        @interface.close if @interface
        @interface = interface
      end
    end

    require 'pathname' # For cleanpath

    #
    # Regularize file name.
    #
    # This is also used as a common funnel place if basename is desired or if
    # we are working remotely and want to change the basename. Or we are
    # eliding filenames.
    #
    def self.canonic_file(filename)
      return filename if ['(irb)', '-e'].include?(filename)

      # For now we want resolved filenames
      if Setting[:basename]
        File.basename(filename)
      else
        Pathname.new(filename).cleanpath.to_s
      end
    end

    def self.protect(mname)
      alias_method "__#{mname}", mname
      module_eval <<-END, __FILE__, __LINE__ + 1
        def #{mname}(*args)
          @mutex.synchronize do
            return unless @interface
            __#{mname}(*args)
          end
        rescue IOError, SystemCallError
          @interface.close
        rescue SignalException
          raise
        rescue
          without_exceptions do
            puts "INTERNAL ERROR!!! #\{$!\}"
            puts $!.backtrace.map{|l| "\t#\{l\}"}.join("\n")
          end
        end
      END
    end

    def at_breakpoint(_context, breakpoint)
      n = Byebug.breakpoints.index(breakpoint) + 1
      file = self.class.canonic_file(breakpoint.source)
      line = breakpoint.pos
      puts "Stopped by breakpoint #{n} at #{file}:#{line}"
    end
    protect :at_breakpoint

    def at_catchpoint(context, excpt)
      file = self.class.canonic_file(context.frame_file(0))
      line = context.frame_line(0)
      puts "Catchpoint at #{file}:#{line}: `#{excpt}' (#{excpt.class})"
    end
    protect :at_catchpoint

    include FileFunctions

    def at_tracing(context, file, line)
      if file != @last_file || line != @last_line || Setting[:tracing_plus]
        path = self.class.canonic_file(file)
        puts "Tracing: #{path}:#{line} #{get_line(file, line)}"
        @last_file, @last_line = file, line
      end

      always_run(context, file, line, 2)
    end
    protect :at_tracing

    def at_line(context, file, line)
      process_commands(context, file, line)
    end
    protect :at_line

    def at_return(context, file, line)
      process_commands(context, file, line)
    end
    protect :at_return

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
      cmds = Command.commands

      state = Byebug::RegularState.new(cmds,
                                       context,
                                       @display,
                                       file,
                                       @interface,
                                       line)

      # Change default when in irb or code included in command line
      Setting[:autolist] = false if ['(irb)', '-e'].include?(file)

      # Bind commands to the current state.
      commands = cmds.map do |cmd_class|
        cmd = cmd_class.new(state)
        cmd.execute if cmd.class.always_run >= run_level
        cmd
      end

      [state, commands]
    end

    #
    # Handle byebug commands.
    #
    def process_commands(context, file, line)
      state, commands = preloop(context, file, line)

      repl(state, commands, context)

      postloop
    end

    #
    # Main byebug's REPL
    #
    def repl(state, commands, context)
      until state.proceed?
        cmd = @interface.read_command(prompt(context))
        return unless cmd

        next if cmd == '' && @last_cmd.nil?

        cmd.empty? ? cmd = @last_cmd : @last_cmd = cmd

        one_cmd(commands, context, cmd)
      end
    end

    #
    # Autoevals a single command
    #
    def one_unknown_cmd(commands, input)
      unless Setting[:autoeval]
        return errmsg("Unknown command: \"#{input}\". Try \"help\"")
      end

      commands.find { |c| c.is_a?(EvalCommand) }.execute
    end

    #
    # Executes a single byebug command
    #
    def one_cmd(commands, context, input)
      cmd = commands.find { |c| c.match(input) }
      return one_unknown_cmd(commands, input) unless cmd

      if context.dead? && !cmd.class.allow_in_post_mortem
        return errmsg('Command unavailable in post mortem mode.')
      end

      cmd.execute
    end

    #
    # Tasks to do before processor loop.
    #
    def preloop(context, file, line)
      state, commands = always_run(context, file, line, 1)

      thread_state = Setting[:testing] ? state : nil
      Thread.current.thread_variable_set('state', thread_state)

      puts 'The program finished.' if program_just_finished?(context)

      puts(state.location) if Setting[:autolist] == 0

      @interface.history.restore if Setting[:autosave]

      [state, commands]
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

    #
    # Tasks to do after processor loop.
    #
    def postloop
      Setting[:autosave] ? @interface.history.save : @interface.history.clear
    end
  end
end
