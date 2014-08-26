require 'slop'
require 'ostruct'
require 'English'
require 'byebug/core'
require 'byebug/options'

module Byebug
  #
  # Responsible for starting the debugger when started from the command line.
  #
  class Runner
    BYEBUG_SCRIPT = File.expand_path('../../../../bin/byebug')
    IGNORED_FILES << BYEBUG_SCRIPT

    #
    # Debug a script only if syntax checks okay.
    #
    def debug_program(options)
      output = `ruby -c "#{Byebug::PROG_SCRIPT}" 2>&1`
      if $CHILD_STATUS.exitstatus != 0
        Byebug.puts output
        exit $CHILD_STATUS.exitstatus
      end

      status = Byebug.debug_load(Byebug::PROG_SCRIPT, options[:stop])
      Byebug.puts "#{status}\n#{status.backtrace}" if status
    end

    #
    # Do a shell-like path lookup for prog_script and return the results. If we
    # can't find anything return prog_script.
    #
    def whence_file(prog_script)
      if prog_script.index(File::SEPARATOR)
        # Don't search since this name has path separator components
        return prog_script
      end

      ENV['PATH'].split(File::PATH_SEPARATOR).each do |dirname|
        prog_script_try = File.join(dirname, prog_script)
        return prog_script_try if File.exist?(prog_script_try)
      end

      # Failure
      prog_script
    end

    #
    # Starts byebug to debug a program
    #
    def run
      opts = Byebug::Options.parse

      return Byebug.puts("\n  Running byebug #{VERSION}\n") if opts[:version]
      return Byebug.puts("#{opts.help}\n") if opts[:help]

      if opts[:remote]
        port, host = opts[:remote].pop.to_i, opts[:remote].pop || 'localhost'
        Byebug.puts "Connecting to byebug server #{host}:#{port}..."
        Byebug.start_client(host, port)
        return
      end

      if ARGV.empty?
        Byebug.puts 'You must specify a program to debug...'
        abort
      end

      # Save debugged program
      prog_script = ARGV.pop
      prog_script = whence_file(prog_script) unless File.exist?(prog_script)

      if Byebug.const_defined?('PROG_SCRIPT')
        Byebug.send(:remove_const, 'PROG_SCRIPT')
      end
      Byebug.const_set('PROG_SCRIPT', File.expand_path(prog_script))

      # Set up trace hook for byebug
      Byebug.start

      # load initrc script (e.g. .byebugrc)
      Byebug.run_init_script(StringIO.new) if opts[:rc]

      # Post Mortem mode status
      Byebug::Setting[:post_mortem] = opts[:'post-mortem']

      # Line Tracing Status
      Byebug::Setting[:linetrace] = opts[:trace]

      loop do
        debug_program(opts)

        break if opts[:quit]

        processor = Byebug::ControlCommandProcessor.new
        processor.process_commands
      end
    end
  end
end
