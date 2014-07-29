module Byebug
  class ShowCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* show (?:\s+(?<setting>\w+))? \s*$/x
    end

    def execute
      key = @match[:setting]
      return print ShowCommand.help if key.nil?

      full_key = Setting.find(key)
      if full_key
        print Setting.settings[full_key.to_sym].to_s
      else
        print "Unknown setting :#{key}\n"
      end
    end

    class << self
      def names
        %w(show)
      end

      def description
        <<-EOD.gsub(/^        /, '')

          show <setting> <value>

          Generic command for showing byebug settings. You can change them with
          the "set" command.

        EOD
      end

      def help(setting = nil)
        return "show #{setting.to_sym} <value>\n\n#{setting.help}" if setting

        description + Setting.format()
      end
    end
  end
end
