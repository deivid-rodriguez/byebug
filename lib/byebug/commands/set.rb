module Byebug
  #
  # Change byebug settings.
  #
  class SetCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* set (?:\s+(?<setting>\w+))? (?:\s+(?<value>\S+))? \s*$/x
    end

    def execute
      key, value = @match[:setting], @match[:value]
      return puts(SetCommand.help) if key.nil? && value.nil?

      full_key = Setting.find(key)
      return errmsg("Unknown setting :#{key}") unless full_key

      if !Setting.boolean?(full_key) && value.nil?
        value, err = nil, "You must specify a value for setting :#{key}"
      elsif Setting.boolean?(full_key)
        value, err = get_onoff(value, key =~ /^no/ ? false : true)
      elsif Setting.integer?(full_key)
        value, err = get_int(value, full_key, 1)
      end
      return errmsg(err) if value.nil?

      Setting[full_key.to_sym] = value

      puts Setting.settings[full_key.to_sym].to_s
    end

    def get_onoff(arg, default)
      return default if arg.nil?

      case arg
      when '1', 'on', 'true'
        true
      when '0', 'off', 'false'
        false
      else
        [nil, "Expecting 'on', 1, true, 'off', 0, false. Got: #{arg}.\n"]
      end
    end

    class << self
      def names
        %w(set)
      end

      def description
        <<-EOD.gsub(/^        /, '')

          set <setting> <value>

          Modifies parts of byebug environment.

          Boolean values take "on", "off", "true", "false", "1" or "0". If you
          don't specify a value, the boolean setting will be enabled.
          Conversely, you can use "set no<setting> to disable them.

          You can see these environment settings with the "show" command.
        EOD
      end

      def help(subcmds = [])
        Setting.help('set', subcmds.first)
      end
    end
  end
end
