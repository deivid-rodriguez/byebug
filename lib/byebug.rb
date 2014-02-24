require 'byebug/byebug'
require 'byebug/version'
require 'byebug/context'
require 'byebug/processor'
require 'byebug/command_processor'
require 'byebug/control_command_processor'
require 'byebug/remote'
require 'stringio'
require 'tracer'
require 'linecache19'

module Byebug

  # List of files byebug will ignore while debugging
  IGNORED_FILES = Dir.glob(File.expand_path('../**/*.rb', __FILE__))

  # Default options to Byebug.start
  DEFAULT_START_SETTINGS = {
    init:        true,  # Set $0 and save ARGV?
    post_mortem: false, # post-mortem debugging on uncaught exception?
    tracing:     nil    # Byebug.tracing? value. true/false resets
  } unless defined?(DEFAULT_START_SETTINGS)

  # Configuration file used for startup commands. Default value is .byebugrc
  INITFILE = '.byebugrc' unless defined?(INITFILE)

  class << self

    # processor modules provide +handler+ object
    attr_accessor :handler
    Byebug.handler = CommandProcessor.new

    attr_accessor :last_exception
    Byebug.last_exception = nil

    def source_reload
      Object.send(:remove_const, 'SCRIPT_LINES__') if
        Object.const_defined?('SCRIPT_LINES__')
      Object.const_set('SCRIPT_LINES__', {})
    end

    #
    # Get line +line_number+ from file named +filename+.
    #
    # @return "\n" if there was a problem. Leaking blanks are stripped off.
    #
    def line_at(filename, line_number)
      source_reload

      return "\n" unless File.exist?(filename)
      line = Tracer::Single.get_line(filename, line_number)

      return "#{line.gsub(/^\s+/, '').chomp}"
    end

    #
    # Add a new breakpoint
    #
    # @param [String] file
    # @param [Fixnum] line
    # @param [String] expr
    #
    def add_breakpoint(file, line, expr=nil)
      breakpoint = Breakpoint.new(file, line, expr)
      breakpoints << breakpoint
      breakpoint
    end

    #
    # Remove a breakpoint
    #
    # @param [integer] breakpoint number
    #
    def remove_breakpoint(id)
      breakpoints.reject! { |b| b.id == id }
    end

    def interface=(value)
      handler.interface = value
    end

    extend Forwardable
    def_delegators :"handler.interface", :print

    #
    # Byebug.start(options) -> bool
    # Byebug.start(options) { ... } -> obj
    #
    # If it's called without a block, it returns +true+ unless byebug was
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
      retval = Byebug._start(&block)
      post_mortem if options[:post_mortem]
      return retval
    end

    #
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
      run_script(cwd_script, out) if File.exist?(cwd_script)

      home_script = File.expand_path(File.join(ENV['HOME'].to_s, INITFILE))
      if File.exist?(home_script) and cwd_script != home_script
         run_script(home_script, out)
      end
    end

    #
    # Runs a script file
    #
    def run_script(file, out = handler.interface, verbose=false)
      interface = ScriptInterface.new(File.expand_path(file), out)
      processor = ControlCommandProcessor.new(interface)
      processor.process_commands(verbose)
    end

    #
    # Activates the post-mortem mode.
    #
    # By calling Byebug.post_mortem method, you install an at_exit hook that
    # intercepts any exception not handled by your script and enables
    # post-mortem mode.
    #
    def post_mortem
      return if self.post_mortem?
      at_exit { handle_post_mortem($!) if post_mortem? }
      self.post_mortem = true
    end

    def handle_post_mortem(exp)
      return if !exp
      Byebug.last_exception = exp
      return if !exp.__bb_context || !exp.__bb_context.calced_stack_size
      orig_tracing = Byebug.tracing?
      Byebug.tracing = false
      handler.at_line(exp.__bb_context, exp.__bb_file, exp.__bb_line)
    ensure
      Byebug.tracing = orig_tracing
    end
    private :handle_post_mortem
  end
end

class Exception
  attr_reader :__bb_file, :__bb_line, :__bb_binding, :__bb_context
end

module Kernel
  #
  # Enters byebug after _steps_into_ line events and _steps_out_ return events
  # occur. Before entering byebug startup, the init script is read.
  #
  def byebug(steps_into = 1, steps_out = 2)
    Byebug.start
    Byebug.run_init_script(StringIO.new)
    if Byebug.current_context.calced_stack_size > 2
      Byebug.current_context.stop_return steps_out if steps_out >= 1
    end
    Byebug.current_context.step_into steps_into if steps_into >= 0
  end

  alias_method :debugger, :byebug
end
