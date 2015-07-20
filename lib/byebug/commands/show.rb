require 'byebug/command'

module Byebug
  #
  # Show byebug settings.
  #
  class ShowCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* show (?:\s+(?<setting>\w+))? \s*$/x
    end

    def description
      <<-EOD
        show <setting> <value>

        #{short_description}

        You can change them with the "set" command.
      EOD
    end

    def short_description
      'Shows byebug settings'
    end

    def execute
      key = @match[:setting]
      return puts(help) unless key

      setting = Setting.find(key)
      return errmsg(pr('show.errors.unknown_setting', key: key)) unless setting

      puts Setting.settings[setting.to_sym]
    end

    def help
      description + Setting.help_all
    end
  end
end
