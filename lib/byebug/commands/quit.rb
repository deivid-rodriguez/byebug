require 'byebug/command'

module Byebug
  #
  # Exit from byebug.
  #
  class QuitCommand < Command
    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def regexp
      /^\s* q(?:uit)? \s* (?:(!|\s+unconditionally))? \s*$/x
    end

    def description
      <<-EOD
        q[uit] [!|unconditionally]

        #{short_description}

        Normally we prompt before exiting. However if the parameter
        "unconditionally" is given or command is suffixed with !, we exit
        without asking further questions.
      EOD
    end

    def short_description
      'Exits byebug'
    end

    def execute
      return unless @match[1] || confirm(pr('quit.confirmations.really'))

      @state.interface.autosave
      @state.interface.close

      Process.exit!
    end
  end
end
