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
      @last_cmd         = nil   # To allow empty (just <RET>) commands
      @last_file        = nil   # Filename the last time we stopped
      @last_line        = nil   # Line number the last time we stopped
      @context_was_dead = false # Assume we haven't started.
    end

    def interface=(interface)
      @mutex.synchronize do
        @interface.close if @interface
        @interface = interface
      end
    end

    require 'pathname'  # For cleanpath

    #
    # Regularize file name.
    #
    # This is also used as a common funnel place if basename is desired or if we
    # are working remotely and want to change the basename. Or we are eliding
    # filenames.
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

    include ParseFunctions

    def at_tracing(context, file, line)
      if file != @last_file || line != @last_line || Setting[:tracing_plus]
        path = self.class.canonic_file(file)
        @last_file, @last_line = file, line
        puts "Tracing: #{path}:#{line} #{get_line(file, line)}"
      end
      always_run(context, file, line, 2)
    end
    protect :at_tracing

    def at_line(context, file, line)
      Byebug.source_reload if Setting[:autoreload]
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
      "(byebug#{context.dead?  ? ':post-mortem' : ''}) "
    end

    #
    # Run commands everytime.
    #
    # For example display commands or possibly the list or irb in an
    # "autolist" or "autoirb".
    #
    # @return List of commands acceptable to run bound to the current state
    #
    def always_run(context, file, line, run_level)
      cmds = Command.commands

      state = State.new(cmds, context, @display, file, @interface, line)

      # Change default when in irb or code included in command line
      Setting[:autolist] = false if ['(irb)', '-e'].include?(file)

      # Bind commands to the current state.
      commands = cmds.map { |cmd| cmd.new(state) }

      commands.select { |cmd| cmd.class.always_run >= run_level }
              .each { |cmd| cmd.execute }

      [state, commands]
    end

    #
    # Splits a command line of the form "cmd1 ; cmd2 ; ... ; cmdN" into an
    # array of commands: [cmd1, cmd2, ..., cmdN]
    #
    def split_commands(cmd_line)
      cmd_line.split(/;/).each_with_object([]) do |v, m|
        if m.empty?
          m << v
        else
          if m.last[-1] == '\\'
            m.last[-1, 1] = ''
            m.last << ';' << v
          else
            m << v
          end
        end
      end
    end

    #
    # Handle byebug commands.
    #
    def process_commands(context, file, line)
      state, commands = always_run(context, file, line, 1)

      if Setting[:testing]
        Thread.current.thread_variable_set('state', state)
      else
        Thread.current.thread_variable_set('state', nil)
      end

      preloop(commands, context)
      puts(state.location) if Setting[:autolist] == 0

      until state.proceed?
        input = if @interface.command_queue.empty?
                  @interface.read_command(prompt(context))
                else
                  @interface.command_queue.shift
                end
        break unless input

        if input == ''
          next unless @last_cmd
          input = @last_cmd
        else
          @last_cmd = input
        end
        split_commands(input).each do |cmd|
          one_cmd(commands, context, cmd)
        end
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
    # Tasks to do before processor loop
    #
    def preloop(_commands, context)
      @context_was_dead = true if context.dead? && !@context_was_dead
      return unless @context_was_dead

      puts 'The program finished.'
      @context_was_dead = false
    end

    class State
      attr_accessor :commands, :context, :display, :file, :frame_pos
      attr_accessor :interface, :line, :previous_line

      def initialize(commands, context, display, file, interface, line)
        @commands, @context, @display = commands, context, display
        @file, @interface, @line = file, interface, line
        @frame_pos, @previous_line, @proceed = 0, nil, false
      end

      extend Forwardable
      def_delegators :@interface, :errmsg, :puts, :confirm

      def proceed?
        @proceed
      end

      def proceed
        @proceed = true
      end

      def location
        path = self.class.canonic_file(@file)
        loc = "#{path} @ #{@line}\n"
        loc += "#{get_line(@file, @line)}\n" unless
          ['(irb)', '-e'].include? @file
        loc
      end
    end
  end
end
