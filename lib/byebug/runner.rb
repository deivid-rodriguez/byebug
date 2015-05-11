require 'optparse'
require 'English'
require 'byebug/core'
require 'byebug/helpers/parse'

module Byebug
  #
  # Responsible for starting the debugger when started from the command line.
  #
  class Runner
    include Helpers::ParseHelper

    #
    # Error class signaling absence of a script to debug
    #
    class NoScript < StandardError; end

    #
    # Error class signaling a non existent script to debug
    #
    class NonExistentScript < StandardError; end

    #
    # Error class signaling a script with invalid Ruby syntax
    #
    class InvalidScript < StandardError; end

    #
    # Special working modes that don't actually start the debugger.
    #
    attr_accessor :help, :version, :remote

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

    #
    # Usage banner.
    #
    def banner
      <<-EOB.gsub(/^ {8}/, '')

          byebug #{Byebug::VERSION}

          Usage: byebug [options] <script.rb> -- <script.rb parameters>

      EOB
    end

    #
    # Starts byebug to debug a program
    #
    def run
      prepare_options.order!($ARGV)

      if version
        Byebug.puts("\n  Running byebug #{version}\n")
        return
      end

      if help
        Byebug.puts("#{help}\n")
        return
      end

      if remote
        Byebug.start_client(*remote)
        return
      end

      setup_cmd_line_args

      loop do
        debug_program

        break if @quit

        processor = Byebug::ControlCommandProcessor.new
        processor.process_commands
      end
    end

    private

    #
    # Processes options passed from the command line
    #
    def prepare_options
      OptionParser.new(banner, 25) do |opts|
        opts.banner = banner

        opts.on '-d', '--debug', 'Set $DEBUG=true' do
          $DEBUG = true
        end

        opts.on('-I', '--include list', 'Add to paths to $LOAD_PATH') do |list|
          $LOAD_PATH.push(list.split(':')).flatten!
        end

        opts.on '-m', '--[no-]post-mortem', 'Use post-mortem mode' do |v|
          Setting[:post_mortem] = v
        end

        opts.on '-q', '--[no-]quit', 'Quit when script finishes' do |v|
          @quit = v
        end

        opts.on '-x', '--[no-]rc', 'Run byebug initialization file' do |v|
          Byebug.run_init_script if v
        end

        opts.on '-s', '--[no-]stop', 'Stop when script is loaded' do |v|
          @stop = v
        end

        opts.on '-r', '--require file', 'Require library before script' do |lib|
          require lib
        end

        opts.on '-R', '--remote [host:]port', 'Remote debug [host:]port' do |p|
          self.remote = Byebug.parse_host_and_port(p)
        end

        opts.on '-t', '--[no-]trace', 'Turn on line tracing' do |v|
          Setting[:linetrace] = v
        end

        opts.on '-v', '--version', 'Print program version' do
          self.version = VERSION
        end

        opts.on('-h', '--help', 'Display this message') do
          self.help = opts.help
        end
      end
    end

    #
    # Extracts debugged program from command line args
    #
    def setup_cmd_line_args
      Byebug.mode = :standalone

      fail(NoScript, 'You must specify a program to debug...') if $ARGV.empty?

      program = which($ARGV.shift)
      program = which($ARGV.shift) if program == which('ruby')
      fail(NonExistentScript, "The script doesn't exist") unless program

      $PROGRAM_NAME = program
    end

    #
    # Debugs a script only if syntax checks okay.
    #
    def debug_program
      ok = syntax_valid?(File.read($PROGRAM_NAME))
      fail(InvalidScript, 'The script has incorrect syntax') unless ok

      error = Byebug.debug_load($PROGRAM_NAME, @stop)
      Byebug.puts "#{status}\n#{status.backtrace}" if error
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
end
