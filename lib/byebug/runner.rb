require 'optparse'
require 'English'
require 'byebug/core'

module Byebug
  #
  # Responsible for starting the debugger when started from the command line.
  #
  class Runner
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
      @stop, @quit = stop, quit
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
    # Debugs a script only if syntax checks okay.
    #
    def debug_program
      check_syntax($PROGRAM_NAME)

      status = Byebug.debug_load($PROGRAM_NAME, @stop)
      Byebug.puts "#{status}\n#{status.backtrace}" if status
    end

    #
    # Exits and outputs error message if syntax of the given program is invalid.
    #
    def check_syntax(program_name)
      output = `ruby -c "#{program_name}" 2>&1`
      return unless $CHILD_STATUS.exitstatus != 0

      Byebug.errmsg(output)
      exit($CHILD_STATUS.exitstatus)
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

      Byebug.setup_cmd_line_args

      loop do
        debug_program

        break if @quit

        processor = Byebug::ControlCommandProcessor.new
        processor.process_commands
      end
    end

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
  end
end
