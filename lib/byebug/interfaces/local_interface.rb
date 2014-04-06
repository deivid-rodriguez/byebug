require 'byebug/history'

module Byebug
  class LocalInterface < Interface
    attr_reader :history

    def initialize
      super
      @history = Byebug::History.new
    end

    def read_command(prompt)
      readline(prompt, true)
    end

    def confirm(prompt)
      readline(prompt, false)
    end

    def print(*args)
      STDOUT.printf(escape(format(*args)))
    end

    def close
    end

    def finalize
      @history.save if save_history?
    end

    def save_history?
      @save_history ||=
        begin
          require 'readline'
          true
        rescue LoadError
          false
        end
    end

    private

      def readline(prompt, hist)
        if save_history?
          begin
            Readline::readline(prompt, hist)
          rescue Interrupt
            print "^C\n"
            retry
          end
        else
          STDOUT.print prompt
          STDOUT.flush
          line = STDIN.gets
          exit unless line
          line.chomp!
          line
        end
      end
  end
end
