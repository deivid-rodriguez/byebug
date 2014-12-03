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
      cmd = Byebug.debugged_program

      if @match[:args]
        cmd += " #{@match[:args]}"
      else
        require 'shellwords'
        cmd += " #{ARGV.compact.shelljoin}"
      end

      # An execv would be preferable to the "exec" below.
      puts pr('restart.success', cmd: cmd)
      exec cmd
    rescue Errno::EOPNOTSUPP
      puts pr('restart.errors.not_available')
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
