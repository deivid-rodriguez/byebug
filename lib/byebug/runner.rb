require 'optparse'
require 'English'
require 'byebug/core'
require 'byebug/version'
require 'byebug/helpers/parse'
require 'byebug/option_setter'
require 'byebug/processors/control_processor'

module Byebug
  #
  # Responsible for starting the debugger when started from the command line.
  #
  class Runner
    include Helpers::ParseHelper

    #
    # Special working modes that don't actually start the debugger.
    #
    attr_reader :help, :version, :remote

    #
    # Signals that we should exit after the debugged program is finished.
    #
    attr_accessor :quit

    #
    # Signals that we should stop before program starts
    #
    attr_accessor :stop

    #
    # Signals that we should run rc scripts before program starts
    #
    attr_writer :init_script

    #
    # @param stop [Boolean] Whether the runner should stop right before
    # starting the program.
    #
    # @param quit [Boolean] Whether the runner should quit right after
    # finishing the program.
    #
    def initialize(stop = true, quit = true)
      @stop = stop
      @quit = quit
    end

    def help=(text)
      @help ||= text

      interface.puts("#{text}\n")
    end

    def version=(number)
      @version ||= number

      interface.puts("\n  Running byebug #{number}\n")
    end

    def remote=(host_and_port)
      @remote ||= Byebug.parse_host_and_port(host_and_port)

      Byebug.start_client(*@remote)
    end

    def init_script
      defined?(@init_script) ? @init_script : true
    end

    #
    # Usage banner.
    #
    def banner
      <<-EOB.gsub(/^ {6}/, '')

        byebug #{Byebug::VERSION}

        Usage: byebug [options] <script.rb> -- <script.rb parameters>

      EOB
    end

    #
    # Starts byebug to debug a program.
    #
    def run
      option_parser.order!($ARGV)
      return if non_script_option? || error_in_script?

      Byebug.run_init_script if init_script

      loop do
        debug_program

        break if quit

        ControlProcessor.new.process_commands
      end
    end

    attr_writer :interface

    def interface
      @interface ||= LocalInterface.new
    end

    #
    # Processes options passed from the command line.
    #
    def option_parser
      @option_parser ||= OptionParser.new(banner, 25) do |opts|
        opts.banner = banner

        OptionSetter.new(self, opts).setup
      end
    end

    #
    # An option that doesn't need a script specified was given
    #
    def non_script_option?
      version || help || remote
    end

    #
    # There is an error with the specified script
    #
    def error_in_script?
      no_script? || non_existing_script? || invalid_script?
    end

    #
    # No script to debug specified
    #
    def no_script?
      return false unless $ARGV.empty?

      print_error('You must specify a program to debug')
      true
    end

    #
    # Extracts debugged program from command line args.
    #
    def non_existing_script?
      Byebug.mode = :standalone

      program = which($ARGV.shift)
      program = which($ARGV.shift) if program == which('ruby')

      if program
        $PROGRAM_NAME = program
        false
      else
        print_error("The script doesn't exist")
        true
      end
    end

    #
    # Checks the debugged script has correct syntax
    #
    def invalid_script?
      return false if syntax_valid?(File.read($PROGRAM_NAME))

      print_error('The script has incorrect syntax')
      true
    end

    #
    # Debugs a script only if syntax checks okay.
    #
    def debug_program
      error = Byebug.debug_load($PROGRAM_NAME, stop)
      puts "#{error}\n#{error.backtrace}" if error
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

    #
    # Prints an error message and a help string
    #
    def print_error(msg)
      interface.errmsg(msg)
      interface.puts(option_parser.help)
    end
  end
end
