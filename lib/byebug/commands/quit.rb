module Byebug

  # Implements byebug "quit" command
  class QuitCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* (?:q(?:uit)?|exit) \s* (!|\s+unconditionally)? \s*$/x
    end

    def execute
      if @match[1] or confirm("Really quit? (y/n) ")
        @state.interface.finalize
        exit! # exit -> exit!: No graceful way to stop...
      end
    end

    class << self
      def names
        %w(quit exit)
      end

      def description
        %{q[uit]|exit [!|unconditionally]\tExits from byebug.

          Normally we prompt before exiting. However if the parameter
          "unconditionally" is given or command is suffixed with !, we exit
          without asking further questions.}
      end
    end
  end
end
