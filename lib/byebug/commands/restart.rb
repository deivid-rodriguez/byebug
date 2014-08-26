module Byebug
  #
  # Restart debugged program from within byebug.
  #
  class RestartCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* (?:restart|R) (?:\s+(?<args>.+))? \s*$/x
    end

    def execute
      prog = PROG_SCRIPT if defined?(PROG_SCRIPT)
      byebug_script = BYEBUG_SCRIPT if defined?(BYEBUG_SCRIPT)

      return errmsg("Don't know name of debugged program") unless prog

      unless File.exist?(File.expand_path(prog))
        return errmsg("Ruby program #{prog} doesn't exist")
      end

      if byebug_script
        cmd = "#{byebug_script} #{prog}"
      else
        puts 'Byebug was not called from the outset...'
        if File.executable?(prog)
          cmd = prog
        else
          puts "Ruby program #{prog} not executable... " \
               "We'll wrap it in a ruby call"
          cmd = "ruby -rbyebug -I#{$LOAD_PATH.join(' -I')} #{prog}"
        end
      end

      if @match[:args]
        cmd += " #{@match[:args]}"
      else
        require 'shellwords'
        cmd += " #{ARGV.compact.shelljoin}"
      end

      # An execv would be preferable to the "exec" below.
      puts "Re exec'ing:\n\t#{cmd}"
      exec cmd
    rescue Errno::EOPNOTSUPP
      puts 'Restart command is not available at this time.'
    end

    class << self
      def names
        %w(restart)
      end

      def description
        %(restart|R [args]

          Restart the program. This is a re-exec - all byebug state
          is lost. If command arguments are passed those are used.)
      end
    end
  end
end
