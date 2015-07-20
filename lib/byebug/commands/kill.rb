require 'byebug/command'

module Byebug
  #
  # Send custom signals to the debugged program.
  #
  class KillCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* (?:kill) \s* (?:\s+(\S+))? \s*$/x
    end

    def description
      <<-EOD
        kill[ signal]

        #{short_description}

        Equivalent of Process.kill(Process.pid)
      EOD
    end

    def short_description
      'Sends a signal to the current process'
    end

    def execute
      if @match[1]
        signame = @match[1]
        unless Signal.list.member?(signame)
          errmsg("signal name #{signame} is not a signal I know about\n")
          return false
        end
        @state.interface.close if 'KILL' == signame
      else
        return unless confirm('Really kill? (y/n) ')
        signame = 'KILL'
      end

      Process.kill(signame, Process.pid)
    end
  end
end
