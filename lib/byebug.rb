require_relative 'byebug.so'
require_relative 'byebug/version'
require_relative 'byebug/context'
require_relative 'byebug/processor'
require 'pp'
require 'stringio'
require 'socket'
require 'thread'
require 'linecache19'

module Byebug

  self.handler = CommandProcessor.new

  # Default options to Byebug.start
  DEFAULT_START_SETTINGS = {
    init:        true,  # Set $0 and save ARGV?
    post_mortem: false, # post-mortem debugging on uncaught exception?
    tracing:     nil    # Byebug.tracing? value. true/false resets
  } unless defined?(DEFAULT_START_SETTINGS)

  # Port number used for remote debugging
  PORT = 8989 unless defined?(PORT)

  # Configuration file used for startup commands. Default value is .byebugrc
  INITFILE = '.byebugrc' unless defined?(INITFILE)

  class << self

    attr_accessor :last_exception
    Byebug.last_exception = nil

    # gdb-style annotation mode. Used in GNU Emacs interface
    attr_accessor :annotate

    # If in remote mode, wait for the remote connection
    attr_accessor :wait_connection

    # A string to look for in caller() to see if the call stack is truncated
    attr_accessor :start_sentinal

    attr_reader :thread, :control_thread, :cmd_port, :ctrl_port

    #
    # Interrupts the current thread
    #
    def interrupt
      current_context.interrupt
    end

    #
    # Interrupts the last debugged thread
    #
    def interrupt_last
      if context = last_context
        return nil unless context.thread.alive?
        context.interrupt
      end
      context
    end

    def source_reload
      Object.send(:remove_const, "SCRIPT_LINES__") if
        Object.const_defined?("SCRIPT_LINES__")
      Object.const_set("SCRIPT_LINES__", {})
      LineCache::clear_file_cache
    end

    # Get line +line_number+ from file named +filename+.
    # @return "\n" if there was a problem. Leaking blanks are stripped off.
    def line_at(filename, line_number)
      @@reload_source_on_change = nil unless defined?(@@reload_source_on_change)
      line = LineCache::getline(filename, line_number, @@reload_source_on_change)
      return "\n" unless line
      return "#{line.gsub(/^\s+/, '').chomp}"
    end

    alias stop remove_tracepoints

    # @param [String] file
    # @param [Fixnum] line
    # @param [String] expr
    def add_breakpoint(file, line, expr=nil)
      breakpoint = Breakpoint.new(file, line, expr)
      breakpoints << breakpoint
      breakpoint
    end

    def remove_breakpoint(id)
      Breakpoint.remove breakpoints, id
    end

    def interface=(value)
      handler.interface = value
    end

    #
    # Byebug.start(options) -> bool
    # Byebug.start(options) { ... } -> obj
    #
    # If it's called without a block it returns +true+, unless byebug was
    # already started.
    #
    # If a block is given, it starts byebug and yields block. After the block is
    # executed it stops byebug with Byebug.stop method. Inside the block you
    # will probably want to have a call to Byebug.byebug. For example:
    #
    #     Byebug.start { byebug; foo }  # Stop inside of foo
    #
    # Also, byebug only allows one invocation of byebug at a time; nested
    # Byebug.start's have no effect and you can't use this inside byebug itself.
    #
    # <i>Note that if you want to stop byebug, you must call Byebug.stop as
    # many times as you called Byebug.start method.</i>
    #
    # +options+ is a hash used to set various debugging options.
    #   :init        - true if you want to save ARGV and some other variables to
    #                  make a byebug restart possible. Only the first time :init
    #                  is set to true the values will get set. Since ARGV is
    #                  saved, you should make sure it hasn't been changed before
    #                  the (first) call.
    #   :post_mortem - true if you want to enter post-mortem debugging on an
    #                  uncaught exception. Once post-mortem debugging is set, it
    #                  can't be unset.
    #
    def start(options={}, &block)
      options = Byebug::DEFAULT_START_SETTINGS.merge(options)
      if options[:init]
        Byebug.const_set('ARGV', ARGV.clone) unless defined? Byebug::ARGV
        Byebug.const_set('PROG_SCRIPT', $0) unless defined? Byebug::PROG_SCRIPT
        Byebug.const_set('INITIAL_DIR', Dir.pwd) unless defined? Byebug::INITIAL_DIR
      end
      Byebug.tracing = options[:tracing] unless options[:tracing].nil?
      Byebug.start_sentinal=caller(0)[1]
      if Byebug.started?
        retval = block && block.call(self)
      else
        retval = Byebug._start(&block)
      end
      if options[:post_mortem]
        post_mortem
      end
      return retval
    end

    #
    # Starts a remote byebug.
    #
    def start_remote(host = nil, port = PORT)
      return if @thread

      self.interface = nil
      start

      if port.kind_of?(Array)
        cmd_port, ctrl_port = port
      else
        cmd_port, ctrl_port = port, port + 1
      end

      ctrl_port = start_control(host, ctrl_port)

      yield if block_given?

      mutex = Mutex.new
      proceed = ConditionVariable.new

      server = TCPServer.new(host, cmd_port)
      @cmd_port = cmd_port = server.addr[1]
      @thread = DebugThread.new do
        while (session = server.accept)
          self.interface = RemoteInterface.new(session)
          if wait_connection
            mutex.synchronize do
              proceed.signal
            end
          end
        end
      end
      if wait_connection
        mutex.synchronize do
          proceed.wait(mutex)
        end
      end
    end
    alias start_server start_remote

    def start_control(host = nil, ctrl_port = PORT + 1) # :nodoc:
      return @ctrl_port if defined?(@control_thread) && @control_thread
      server = TCPServer.new(host, ctrl_port)
      @ctrl_port = server.addr[1]
      @control_thread = DebugThread.new do
        while (session = server.accept)
          interface = RemoteInterface.new(session)
          processor = ControlCommandProcessor.new(interface)
          processor.process_commands
        end
      end
      @ctrl_port
    end

    #
    # Connects to the remote byebug
    #
    def start_client(host = 'localhost', port = PORT)
      require "socket"
      interface = Byebug::LocalInterface.new
      socket = TCPSocket.new(host, port)
      puts "Connected."

      catch(:exit) do
        while (line = socket.gets)
          case line
          when /^PROMPT (.*)$/
            input = interface.read_command($1)
            throw :exit unless input
            socket.puts input
          when /^CONFIRM (.*)$/
            input = interface.confirm($1)
            throw :exit unless input
            socket.puts input
          else
            print line
          end
        end
      end
      socket.close
    end

    ##
    # Runs normal byebug initialization scripts.
    #
    # Reads and executes the commands from init file (if any) in the current
    # working directory.  This is only done if the current directory is
    # different from your home directory.  Thus, you can have more than one init
    # file, one generic in your home directory, and another, specific to the
    # program you are debugging, in the directory where you invoke byebug.
    #
    def run_init_script(out = handler.interface)
      cwd_script  = File.expand_path(File.join(".", INITFILE))
      run_script(cwd_script, out) if File.exists?(cwd_script)

      home_script = File.expand_path(File.join(ENV['HOME'].to_s, INITFILE))
      if File.exists?(home_script) and cwd_script != home_script
         run_script(home_script, out)
      end
    end

    ##
    # Runs a script file
    #
    def run_script(file, out = handler.interface, verbose=false)
      interface = ScriptInterface.new(File.expand_path(file), out)
      processor = ControlCommandProcessor.new(interface)
      processor.process_commands(verbose)
    end

    ##
    # Activates the post-mortem mode. There are two ways of using it:
    #
    # == Global post-mortem mode
    # By calling Byebug.post_mortem method without a block, you install an
    # at_exit hook that intercepts any exception not handled by your script
    # and enables post-mortem mode.
    #
    # == Local post-mortem mode
    #
    # If you know that a particular block of code raises an exception you can
    # enable post-mortem mode by wrapping this block with Byebug.post_mortem,
    # e.g.
    #
    #   def offender
    #      raise 'error'
    #   end
    #   Byebug.post_mortem do
    #      ...
    #      offender
    #      ...
    #   end
    def post_mortem
      if block_given?
        old_post_mortem = self.post_mortem?
        begin
          self.post_mortem = true
          yield
        rescue Exception => exp
          handle_post_mortem(exp)
          raise
        ensure
          self.post_mortem = old_post_mortem
        end
      else
        return if self.post_mortem?
        self.post_mortem = true
        debug_at_exit do
          handle_post_mortem($!) if $! && post_mortem?
        end
      end
    end

    def handle_post_mortem(exp)
      return if !exp || !exp.__debug_context ||
        exp.__debug_context.stack_size == 0
      #Byebug.suspend
      orig_tracing = Byebug.tracing?, Byebug.current_context.tracing
      Byebug.tracing = Byebug.current_context.tracing = false
      Byebug.last_exception = exp
      handler.at_line(exp.__debug_context, exp.__debug_file, exp.__debug_line)
    ensure
      Byebug.tracing, Byebug.current_context.tracing = orig_tracing
      #Byebug.resume
    end
    private :handle_post_mortem

  end

  class DebugThread # :nodoc:
  end

  class ThreadsTable # :nodoc:
  end

end

class Exception
  attr_reader :__debug_file, :__debug_line, :__debug_binding, :__debug_context
end

class Module
  #
  # Wraps the +meth+ method with Byebug.start {...} block.
  #
  def debug_method(meth)
    old_meth = "__debugee_#{meth}"
    old_meth = "#{$1}_set" if old_meth =~ /^(.+)=$/
    alias_method old_meth.to_sym, meth
    class_eval <<-EOD
    def #{meth}(*args, &block)
      Byebug.start do
        byebug 2
        #{old_meth}(*args, &block)
      end
    end
    EOD
  end

  #
  # Wraps the +meth+ method with Byebug.post_mortem {...} block.
  #
  def post_mortem_method(meth)
    old_meth = "__postmortem_#{meth}"
    old_meth = "#{$1}_set" if old_meth =~ /^(.+)=$/
    alias_method old_meth.to_sym, meth
    class_eval <<-EOD
    def #{meth}(*args, &block)
      Byebug.start do |dbg|
        dbg.post_mortem do
          #{old_meth}(*args, &block)
        end
      end
    end
    EOD
  end
end

module Kernel

  ##
  # Enters byebug in the current thread after _steps_ line events occur.
  #
  # Before entering byebug startup, the init script is read. Setting _steps_ to
  # 0 will cause a break in byebug's subroutine and not wait for a line event to
  # occur. You will have to go "up 1" in order to be back to your debugged
  # program from byebug. Setting _steps_ to 0 could be useful if you want to
  # stop right after the last statement in some scope, because the next step
  # will take you out of some scope.
  def byebug(steps = 1)
    Byebug.start
    Byebug.run_init_script(StringIO.new)
    if 0 == steps
      Byebug.current_context.stop_frame = 0
    else
      Byebug.current_context.stop_next = steps
    end
  end
  alias breakpoint byebug unless respond_to?(:breakpoint)

  ##
  # Returns a binding of n-th call frame
  #
  def binding_n(n = 0)
    Byebug.skip do
      Byebug.current_context.frame_binding(n+1)
    end
  end
end
