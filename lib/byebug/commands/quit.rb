require 'byebug/command'

module Byebug
  #
  # Exit from byebug.
  #
  class QuitCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* q(?:uit)? \s* (?:(!|\s+unconditionally))? \s*$/x
    end

    def execute
      return unless @match[1] || confirm(pr('quit.confirmations.really'))

      @state.interface.autosave
      @state.interface.close
      exit! # exit -> exit!: No graceful way to stop...
    end

    def description
      <<-EOD
        q[uit] [!|unconditionally]

        Exits from byebug.

        Normally we prompt before exiting. However if the parameter
        "unconditionally" is given or command is suffixed with !, we exit
        without asking further questions.
      EOD
    end
  end
end
