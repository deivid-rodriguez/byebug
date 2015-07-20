require 'byebug/command'
require 'shellwords'

module Byebug
  #
  # Restart debugged program from within byebug.
  #
  class RestartCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* restart (?:\s+(?<args>.+))? \s*$/x
    end

    def description
      <<-EOD
        restart [args]

        #{short_description}

        This is a re-exec - all byebug state is lost. If command arguments are
        passed those are used.
      EOD
    end

    def short_description
      'Restarts the debugged program'
    end

    def execute
      argv = [$PROGRAM_NAME]

      argv.unshift(byebug_script) if Byebug.mode == :standalone

      argv += (@match[:args] ? @match[:args].shellsplit : $ARGV.compact)

      puts pr('restart.success', cmd: argv.shelljoin)
      exec(*argv)
    end

    private

    def byebug_script
      Gem.bin_path('byebug', 'byebug')
    end
  end
end
