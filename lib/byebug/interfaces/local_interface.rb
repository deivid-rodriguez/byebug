require 'byebug/history'

module Byebug
  #
  # Interface class for standard byebug use.
  #
  class LocalInterface < Interface
    attr_reader :history

    def initialize
      super
      History.load
    end

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
      History.save
    end

    private

    def readline(prompt, hist)
      Readline.readline(prompt, hist)
    rescue Interrupt
      puts '^C'
      retry
    end
  end
end
