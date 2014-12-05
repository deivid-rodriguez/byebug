require 'byebug/byebug'
require 'byebug/version'
require 'byebug/context'
require 'byebug/breakpoint'
require 'byebug/interface'
require 'byebug/processor'
require 'byebug/setting'
require 'byebug/remote'
require 'byebug/printers/plain'

module Byebug
  #
  # List of files byebug will ignore while debugging
  #
  IGNORED_FILES = Dir.glob(File.expand_path('../**/*.rb', __FILE__))

  #
  # Tells whether a file is ignored by the debugger.
  #
  # @param path [String] filename to be checked.
  #
  def self.ignored?(path)
    IGNORED_FILES.include?(path)
  end

  #
  # Configuration file used for startup commands. Default value is .byebugrc
  #
  INIT_FILE = '.byebugrc' unless defined?(INIT_FILE)

  class << self
    attr_accessor :handler, :printer
    attr_reader :debugged_program

    extend Forwardable
    def_delegators :handler, :errmsg, :puts
  end

  Byebug.handler = CommandProcessor.new

  #
  # Runs normal byebug initialization scripts.
  #
  # Reads and executes the commands from init file (if any) in the current
  # working directory. This is only done if the current directory is different
  # from your home directory. Thus, you can have more than one init file, one
  # generic in your home directory, and another, specific to the program you
  # are debugging, in the directory where you invoke byebug.
  #
  def self.run_init_script
    home_rc = File.expand_path(File.join(ENV['HOME'].to_s, INIT_FILE))
    run_script(home_rc) if File.exist?(home_rc)

    cwd_rc  = File.expand_path(File.join('.', INIT_FILE))
    run_script(cwd_rc) if File.exist?(cwd_rc) && cwd_rc != home_rc
  end

  #
  # Runs a script file
  #
  def self.run_script(file, verbose = false)
    interface = ScriptInterface.new(File.expand_path(file), verbose)
    processor = ControlCommandProcessor.new(interface)
    processor.process_commands
  end

  self.printer ||= Byebug::Printers::Plain.new

  def self.set_debugged_program
    @debugged_program = program_from_args
  end

  #
  # Extracts debugged program from command line args
  #
  def self.program_from_args
    return $PROGRAM_NAME unless $PROGRAM_NAME.include?('bin/byebug')

    abort_with_err('You must specify a program to debug...') if ARGV.empty?

    argv = ARGV.dup

    program = which(argv.shift)
    program = which(argv.shift) if program == which('ruby')
    abort_with_err("The script doesn't exist") unless program

    program
  end

  private

  #
  # Cross-platform way of finding an executable in the $PATH.
  # Borrowed from: http://stackoverflow.com/questions/2108727
  #
  def self.which(cmd)
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

  #
  # Prints an error message and aborts Byebug execution
  #
  def self.abort_with_err(msg)
    Byebug.errmsg(msg)
    abort
  end
end

#
# Extends the extension class to be able to pass information about the
# debugging environment from the c-extension to the user.
#
class Exception
  attr_reader :__bb_file, :__bb_line, :__bb_binding, :__bb_context
end
