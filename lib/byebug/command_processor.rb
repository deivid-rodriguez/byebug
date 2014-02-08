require 'forwardable'
require_relative 'interface'
require_relative 'command'

module Byebug

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
      if Command.settings[:basename]
        File.basename(filename)
      else
        Pathname.new(filename).cleanpath.to_s
      end
    end

    def self.protect(mname)
      alias_method "__#{mname}", mname
      module_eval <<-END, __FILE__, __LINE__+1
        def #{mname}(*args)
          @mutex.synchronize do
            return unless @interface
            __#{mname}(*args)
          end
        rescue IOError, Errno::EPIPE
          self.interface = nil
        rescue SignalException
          raise
        rescue Exception
          print "INTERNAL ERROR!!! #\{$!\}\n" rescue nil
          print $!.backtrace.map{|l| "\t#\{l\}"}.join("\n") rescue nil
        end
      END
    end

    def at_breakpoint(context, breakpoint)
      n = Byebug.breakpoints.index(breakpoint) + 1
      file = CommandProcessor.canonic_file(breakpoint.source)
      line = breakpoint.pos
      print "Stopped by breakpoint #{n} at #{file}:#{line}\n"
    end
    protect :at_breakpoint

    def at_catchpoint(context, excpt)
      file = CommandProcessor.canonic_file(context.frame_file(0))
      line = context.frame_line(0)
      print "Catchpoint at %s:%d: `%s' (%s)\n", file, line, excpt, excpt.class
    end
    protect :at_catchpoint

    def at_tracing(context, file, line)
      if file != @last_file || line != @last_line || Command.settings[:linetrace_plus]
        @last_file, @last_line = file, line
        print "Tracing: #{CommandProcessor.canonic_file(file)}:#{line} " \
              "#{Byebug.line_at(file,line)}\n"
      end
      always_run(context, file, line, 2)
    end
    protect :at_tracing

    def at_line(context, file, line)
      Byebug.source_reload if Command.settings[:autoreload]
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
        return "(byebug#{context.dead?  ? ':post-mortem' : ''}) "
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

        # Remove some commands in post-mortem
        cmds = cmds.find_all { |cmd| cmd.allow_in_post_mortem } if context.dead?

        state = State.new(cmds, context, @display, file, @interface, line)

        # Change default when in irb or code included in command line
        Command.settings[:autolist] = 0 if ['(irb)', '-e'].include?(file)

        # Bind commands to the current state.
        commands = cmds.map { |cmd| cmd.new(state) }

        commands.select { |cmd| cmd.class.always_run >= run_level }
                .each { |cmd| cmd.execute }

        return state, commands
      end

      #
      # Splits a command line of the form "cmd1 ; cmd2 ; ... ; cmdN" into an
      # array of commands: [cmd1, cmd2, ..., cmdN]
      #
      def split_commands(cmd_line)
        cmd_line.split(/;/).inject([]) do |m, v|
          if m.empty?
            m << v
          else
            if m.last[-1] == ?\\
              m.last[-1,1] = ''
              m.last << ';' << v
            else
              m << v
            end
          end
          m
        end
      end

      #
      # Handle byebug commands.
      #
      def process_commands(context, file, line)
        state, commands = always_run(context, file, line, 1)

        if Command.settings[:testing]
          Thread.current.thread_variable_set('state', state)
        else
          Thread.current.thread_variable_set('state', nil)
        end

        preloop(commands, context)
        print state.location if Command.settings[:autolist] == 0

        while !state.proceed?
          input = @interface.command_queue.empty? ?
                  @interface.read_command(prompt(context)) :
                  @interface.command_queue.shift
          break unless input
          catch(:debug_error) do
            if input == ""
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
      end

      #
      # Executes a single byebug command
      #
      def one_cmd(commands, context, input)
        if cmd = commands.find { |c| c.match(input) }
          if context.dead? && cmd.class.need_context
            print "Command is unavailable\n"
          else
            cmd.execute
          end
        else
          unknown_cmd = commands.find { |c| c.class.unknown }
          if unknown_cmd
            unknown_cmd.execute
          else
            errmsg "Unknown command: \"#{input}\".  Try \"help\".\n"
          end
        end
      end

      #
      # Tasks to do before processor loop
      #
      def preloop(commands, context)
        @context_was_dead = true if context.dead? and not @context_was_dead

        if @context_was_dead
          print "The program finished.\n"
          @context_was_dead = false
        end
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
        def_delegators :@interface, :errmsg, :print, :confirm

        def proceed?
          @proceed
        end

        def proceed
          @proceed = true
        end

        def location
          loc = "#{CommandProcessor.canonic_file(@file)} @ #{@line}\n"
          loc += "#{Byebug.line_at(@file, @line)}\n" unless
            ['(irb)', '-e'].include? @file
          loc
        end
      end

  end # class CommandProcessor
  
end
