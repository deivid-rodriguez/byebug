module Byebug
  class RestartCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* (?:restart|R) (?:\s+(?<args>.+))? \s*$/x
    end

    def execute
      prog = Byebug::PROG_SCRIPT if defined?(Byebug::PROG_SCRIPT)
      byebug_script = Byebug::BYEBUG_SCRIPT if defined?(Byebug::BYEBUG_SCRIPT)

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

  class InterruptCommand < Command
    self.allow_in_control     = true
    self.allow_in_post_mortem = false

    def regexp
      /^\s*i(?:nterrupt)?\s*$/
    end

    def execute
      context = Byebug.thread_context(Thread.main)
      context.interrupt
    end

    class << self
      def names
        %w(interrupt)
      end

      def description
        %{i|nterrupt\t interrupt the program}
      end
    end
  end
end
