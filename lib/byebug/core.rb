require 'byebug/byebug'
require 'byebug/version'
require 'byebug/context'
require 'byebug/breakpoint'
require 'byebug/interface'
require 'byebug/processor'
require 'byebug/remote'
require 'byebug/printers/plain'

module Byebug
  extend self

  class NoScript < StandardError
  end

  class NonExistentScript < StandardError
  end

  #
  # Configuration file used for startup commands. Default value is .byebugrc
  #
  INIT_FILE = '.byebugrc' unless defined?(INIT_FILE)

  #
  # Main debugger's processor
  #
  attr_accessor :handler
  self.handler = CommandProcessor.new

  #
  # Main debugger's printer
  #
  attr_accessor :printer
  self.printer = Printers::Plain.new

  extend Forwardable
  def_delegators :handler, :errmsg, :puts

  #
  # Running mode of the debugger. Can be either:
  #
  # * :attached => Attached to a running program through the `byebug` method.
  # * :standalone => Started through `bin/byebug` script.
  #
  attr_accessor :mode

  #
  # Runs normal byebug initialization scripts.
  #
  # Reads and executes the commands from init file (if any) in the current
  # working directory. This is only done if the current directory is different
  # from your home directory. Thus, you can have more than one init file, one
  # generic in your home directory, and another, specific to the program you
  # are debugging, in the directory where you invoke byebug.
  #
  def run_init_script
    home_rc = File.expand_path(File.join(ENV['HOME'].to_s, INIT_FILE))
    run_script(home_rc) if File.exist?(home_rc)

    cwd_rc = File.expand_path(File.join('.', INIT_FILE))
    run_script(cwd_rc) if File.exist?(cwd_rc) && cwd_rc != home_rc
  end

  #
  # Extracts debugged program from command line args
  #
  def setup_cmd_line_args
    unless $PROGRAM_NAME.include?('bin/byebug')
      self.mode = :attached
      return
    end

    self.mode = :standalone

    fail(NoScript, 'You must specify a program to debug...') if $ARGV.empty?

    program = which($ARGV.shift)
    program = which($ARGV.shift) if program == which('ruby')
    fail(NonExistentScript, "The script doesn't exist") unless program

    $PROGRAM_NAME = program
  end

  private

  #
  # Runs a script file
  #
  def run_script(file, verbose = false)
    interface = ScriptInterface.new(file, verbose)
    processor = ControlCommandProcessor.new(interface)
    processor.process_commands
  end

  #
  # Cross-platform way of finding an executable in the $PATH.
  # Borrowed from: http://stackoverflow.com/questions/2108727
  #
  def which(cmd)
    return File.expand_path(cmd) if File.exist?(cmd)

    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable?(exe) && !File.directory?(exe)
      end
    end

    nil
  end
end

#
# Extends the extension class to be able to pass information about the
# debugging environment from the c-extension to the user.
#
class Exception
  attr_reader :__bb_file, :__bb_line, :__bb_binding, :__bb_context
end
