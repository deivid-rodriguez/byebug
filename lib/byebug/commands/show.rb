module Byebug

  # Implements byebug "show" command.
  class ShowCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* show (?:\s+(?<setting>\w+))? \s*$/x
    end

    def execute
      key = @match[:setting]
      return print ShowCommand.help(nil) if key.nil?

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
        %{Generic command for showing things about byebug.}
      end
    end
  end

end
