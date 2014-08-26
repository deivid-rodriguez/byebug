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

      full_key = Setting.find(key)
      return errmsg("Unknown setting :#{key}") unless full_key

      puts Setting.settings[full_key.to_sym].to_s
    end

    class << self
      def names
        %w(show)
      end

      def description
        <<-EOD.gsub(/^ {8}/, '')

          show <setting> <value>

          Generic command for showing byebug settings. You can change them with
          the "set" command.

        EOD
      end

      def help(subcmds = [])
        Setting.help('show', subcmds.first)
      end
    end
  end
end
