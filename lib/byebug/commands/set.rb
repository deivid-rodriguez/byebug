module Byebug
  class SetCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* set (?:\s+(?<setting>\w+))? (?:\s+(?<value>\S+))? \s*$/x
    end

    def execute
      key, value = @match[:setting], @match[:value]
      return print SetCommand.help if key.nil? && value.nil?

      full_key = Setting.find(key)
      return print "Unknown setting :#{key}\n" unless full_key

      if !Setting.boolean?(full_key) && value.nil?
        return print "You must specify a value for setting :#{key}\n"
      elsif Setting.boolean?(full_key)
        value = get_onoff(value, key =~ /^no/ ? false : true)
      elsif Setting.integer?(full_key)
        return unless value = get_int(value, full_key, 1)
      end

      Setting[full_key.to_sym] = value

      return print Setting.settings[full_key.to_sym].to_s
    end

    def get_onoff(arg, default)
      return default if arg.nil?
      case arg
      when '1', 'on', 'true'
        return true
      when '0', 'off', 'false'
        return false
      else
        print "Expecting 'on', 1, true, 'off', 0, false. Got: #{arg}.\n"
        raise RuntimeError
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

      def help(setting = nil)
        return "set #{setting.to_sym} <value>\n\n#{setting.help}" if setting

        description + Setting.format()
      end
    end
  end
end
