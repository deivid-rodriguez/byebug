require 'optparse'
require 'English'
require 'byebug/core'

module Byebug
  #
  # Responsible for starting the debugger when started from the command line.
  #
  class Runner
    BYEBUG_SCRIPT = File.expand_path('../../../../bin/byebug')
    IGNORED_FILES << BYEBUG_SCRIPT

    #
    # @param stop [Boolean] Whether the runner should stop right before
    # starting the program.
    #
    # @param quit [Boolean] Whether the runner should quit right after
    # finishing the program.
    #
    def initialize(stop = true, quit = true)
      @stop, @quit = stop, quit
    end

    #
    # Set of options that byebug's script accepts.
    #
    def banner
      <<-EOB.gsub(/^ {8}/, '')

        byebug #{Byebug::VERSION}

        Usage: byebug [options] <script.rb> -- <script.rb parameters>
      EOB
    end

    #
    # Debugs a script only if syntax checks okay.
    #
    def debug_program
      output = `ruby -c "#{Byebug.debugged_program}" 2>&1`
      if $CHILD_STATUS.exitstatus != 0
        Byebug.puts output
        exit $CHILD_STATUS.exitstatus
      end

      status = Byebug.debug_load(Byebug.debugged_program, @stop)
      Byebug.puts "#{status}\n#{status.backtrace}" if status
    end

    #
    # Starts byebug to debug a program
    #
    def run
      prepare_options.order!(ARGV)

      Byebug.start_debugger

      loop do
        debug_program

        break if @quit

        processor = Byebug::ControlCommandProcessor.new
        processor.process_commands
      end
    end

    def prepare_options
      OptionParser.new(banner, 2) do |opts|
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

        opts.on '-R', '--remote [HOST:]PORT', 'remote debug [host:]port' do |p|
          @host, @port = Byebug.parse_host_and_port(p)
          Byebug.start_client(@host, @port)
          exit(0)
        end

        opts.on '-t', '--[no-]trace', 'Turn on line tracing' do |v|
          Setting[:linetrace] = v
        end

        opts.on '-v', '--version', 'Print program version' do
          exit_with_info("\n  Running byebug #{VERSION}\n")
        end

        opts.on '-h', '--help', 'Display this message' do
          exit_with_info(opts.help)
        end
      end
    end

    private

    #
    # Prints a message and exits Byebug
    #
    def exit_with_info(msg)
      Byebug.puts(msg)
      exit(0)
    end
  end
end
