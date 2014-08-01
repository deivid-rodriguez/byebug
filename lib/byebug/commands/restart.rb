module Byebug
  class RestartCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* (?:restart|R) (?:\s+(?<args>.+))? \s*$/x
    end

    def execute
      prog = PROG_SCRIPT if defined?(PROG_SCRIPT)
      byebug_script = BYEBUG_SCRIPT if defined?(BYEBUG_SCRIPT)

      return errmsg "Don't know name of debugged program\n" unless prog

      unless File.exist?(File.expand_path(prog))
        return errmsg "Ruby program #{prog} doesn't exist\n"
      end

      if byebug_script
        cmd = "#{byebug_script} #{prog}"
      else
        print "Byebug was not called from the outset...\n"
        if File.executable?(prog)
          cmd = prog
        else
          print "Ruby program #{prog} not executable... We'll wrap it in a ruby call\n"
          cmd = "ruby -rbyebug -I#{$:.join(' -I')} #{prog}"
        end
      end

      if @match[:args]
        cmd += " #{@match[:args]}"
      else
        require 'shellwords'
        cmd += " #{ARGV.compact.shelljoin}"
      end

      # An execv would be preferable to the "exec" below.
      print "Re exec'ing:\n\t#{cmd}\n"
      exec cmd
    rescue Errno::EOPNOTSUPP
      print "Restart command is not available at this time.\n"
    end

    class << self
      def names
        %w(restart)
      end

      def description
        %{restart|R [args]

          Restart the program. This is a re-exec - all byebug state
          is lost. If command arguments are passed those are used.}
      end
    end
  end
end
