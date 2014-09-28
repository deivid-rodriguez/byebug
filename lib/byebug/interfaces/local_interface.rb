module Byebug
  #
  # Interface class for standard byebug use.
  #
  class LocalInterface < Interface
    def read_command(prompt)
      readline(prompt, true)
    end

    def confirm(prompt)
      readline(prompt, false)
    end

    def puts(*args)
      STDOUT.puts(*args)
    end

    def close
    end

    private

    def readline(prompt, hist)
      line = Readline.readline(prompt, false)
    rescue Interrupt
      puts('^C')
      retry
    ensure
      save_history(line) if hist
    end
  end
end
