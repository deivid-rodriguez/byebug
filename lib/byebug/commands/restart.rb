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
      prog = Byebug.debugged_program

      if defined?(BYEBUG_SCRIPT)
        cmd = "#{BYEBUG_SCRIPT} #{prog}"
      else
        puts 'Byebug was not called from the outset...'
        if File.executable?(prog)
          cmd = prog
        else
          puts "Program #{prog} not executable... Wrapping it in a ruby call"
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
