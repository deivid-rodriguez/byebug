require 'byebug/byebug'
require 'byebug/version'
require 'byebug/context'
require 'byebug/interface'
require 'byebug/processor'
require 'byebug/setting'
require 'byebug/remote'
require 'stringio'
require 'tracer'
require 'linecache19'

module Byebug

  # List of files byebug will ignore while debugging
  IGNORED_FILES = Dir.glob(File.expand_path('../**/*.rb', __FILE__))

  # Configuration file used for startup commands. Default value is .byebugrc
  INITFILE = '.byebugrc' unless defined?(INITFILE)

  # Stores program being debugged to make restarts possible
  PROG_SCRIPT = $0 unless defined?(PROG_SCRIPT)

  class << self

    # processor modules provide +handler+ object
    attr_accessor :handler
    Byebug.handler = CommandProcessor.new

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
      self.post_mortem = true
      at_exit { handle_post_mortem if post_mortem? }
    end

    def handle_post_mortem
      context = raised_exception.__bb_context
      file    = raised_exception.__bb_file
      line    = raised_exception.__bb_line
      handler.at_line(context, file, line)
    end
    private :handle_post_mortem
  end
end

class Exception
  attr_reader :__bb_file, :__bb_line, :__bb_binding, :__bb_context
end

module Kernel
  #
  # Enters byebug right before (or right after if _before_ is false) return
  # events occur. Before entering byebug the init script is read.
  #
  def byebug(steps_out = 1, before = true)
    Byebug.run_init_script(StringIO.new)
    Byebug.start
    Byebug.current_context.step_out(steps_out, before)
  end

  alias_method :debugger, :byebug
end
