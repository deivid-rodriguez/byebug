module Byebug

  class RestartCommand < Command
    self.allow_in_control = true

    def regexp
      / ^\s*
      (?:restart|R)
      (?:\s+ (\S?.*\S))? \s*
      $
      /ix
    end

    def execute
      if not defined? Byebug::PROG_SCRIPT
        errmsg "Don't know name of debugged program\n"
        return
      end

      if not File.exist?(File.expand_path(Byebug::PROG_SCRIPT))
        errmsg "Ruby program #{Byebug::PROG_SCRIPT} doesn't exist\n"
        return
      end

      if not defined? Byebug::BYEBUG_SCRIPT
        print "Byebug was not called from the outset...\n"
        if not File.executable?(Byebug::PROG_SCRIPT)
          print "Ruby program #{Byebug::PROG_SCRIPT} not executable... " \
                "We'll add a call to Ruby.\n"
          ruby = begin defined?(Gem) ? Gem.ruby : "ruby" rescue "ruby" end
          byebug_script = "#{ruby} -I#{$:.join(' -I')} #{Byebug::PROG_SCRIPT}"
        else
          byebug_script = Byebug::PROG_SCRIPT
        end
      else
        byebug_script = Byebug::BYEBUG_SCRIPT
      end

      begin
        Dir.chdir(Byebug::INITIAL_DIR)
      rescue
        print "Failed to change initial directory #{Byebug::INITIAL_DIR}"
      end

      if @match[1]
        argv = [Byebug::PROG_SCRIPT] + @match[1].split(/[ \t]+/)
      else
        if not defined? Command.settings[:argv]
          errmsg "Arguments have not been set. Use 'set args' to set them.\n"
          return
        else
          argv = Command.settings[:argv]
        end
      end
      cmd = "#{byebug_script} #{argv.compact.join(' ')}"

      # An execv would be preferable to the "exec" below.
      print "Re exec'ing:\n\t#{cmd}\n"
      exec cmd
    rescue Errno::EOPNOTSUPP
      print "Restart command is not available at this time.\n"
    end

    class << self
      def help_command
        'restart'
      end

      def help(cmd)
        %{
          restart|R [args]
          Restart the program. This is a re-exec - all byebug state
          is lost. If command arguments are passed those are used.
        }
      end
    end
  end

  class InterruptCommand < Command # :nodoc:
    self.allow_in_control     = true
    self.allow_in_post_mortem = false
    self.event                = false
    self.need_context         = true

    def regexp
      /^\s*i(?:nterrupt)?\s*$/
    end

    def execute
      unless Byebug.interrupt_last
        context = Byebug.thread_context(Thread.main)
        context.interrupt
      end
    end

    class << self
      def help_command
        'interrupt'
      end

      def help(cmd)
        %{
          i[nterrupt]\tinterrupt the program
        }
      end
    end
  end
end
