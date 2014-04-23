module Byebug
  class RestartCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* (?:restart|R) (?:\s+(.+))? \s*$/x
    end

    def execute
      return errmsg "Don't know name of debugged program\n" unless
        defined?(Byebug::PROG_SCRIPT)

      return errmsg "Ruby program #{Byebug::PROG_SCRIPT} doesn't exist\n" unless
        File.exist?(File.expand_path(Byebug::PROG_SCRIPT))

      if not defined?(Byebug::BYEBUG_SCRIPT)
        print "Byebug was not called from the outset...\n"
        if File.executable?(Byebug::PROG_SCRIPT)
          cmd = Byebug::PROG_SCRIPT
        else
          print "Ruby program #{Byebug::PROG_SCRIPT} not executable... " \
                "We'll wrap it in a ruby call\n"
          cmd = "ruby -rbyebug -I#{$:.join(' -I')} #{Byebug::PROG_SCRIPT}"
        end
        args = ARGV[1..-1]
      else
        cmd = "#{Byebug::BYEBUG_SCRIPT} #{Byebug::PROG_SCRIPT}"
        args = ARGV[2..-1]
      end

      begin
        Dir.chdir(Byebug::INITIAL_DIR)
      rescue
        print "Failed to change initial directory #{Byebug::INITIAL_DIR}"
      end

      if @match[1]
        cmd += " #{@match[1]}"
      else
        require 'shellwords'
        cmd += " #{args.compact.shelljoin}"
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
