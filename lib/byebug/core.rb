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
  # Configuration file used for startup commands. Default value is .byebugrc
  #
  INIT_FILE = '.byebugrc' unless defined?(INIT_FILE)

  class << self
    attr_accessor :handler, :debugged_program, :printer

    extend Forwardable
    def_delegators :handler, :interface, :interface=, :errmsg, :puts
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
    cwd_rc  = File.expand_path(File.join('.', INIT_FILE))
    run_script(cwd_rc) if File.exist?(cwd_rc)

    home_rc = File.expand_path(File.join(ENV['HOME'].to_s, INIT_FILE))
    run_script(home_rc) if File.exist?(home_rc) && cwd_rc != home_rc
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
end

#
# Extends the extension class to be able to pass information about the
# debugging environment from the c-extension to the user.
#
class Exception
  attr_reader :__bb_file, :__bb_line, :__bb_binding, :__bb_context
end
