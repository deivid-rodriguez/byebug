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

    def execute
      key = @match[:setting]
      return puts(self.class.help) if key.nil?

      setting = Setting.find(key)
      return errmsg(pr('show.errors.unknown_setting', key: key)) unless setting

      puts Setting.settings[setting.to_sym]
    end

    class << self
      def names
        %w(show)
      end

      def description
        prettify <<-EOD
          show <setting> <value>

          Generic command for showing byebug settings. You can change them with
          the "set" command.
        EOD
      end

      def help(subcmd = nil)
        Setting.help('show', subcmd)
      end
    end
  end
end
