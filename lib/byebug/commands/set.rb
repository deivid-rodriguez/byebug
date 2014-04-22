module Byebug

  # Implements byebug "set" command.
  class SetCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* set (?:\s+(?<setting>\w+))? (?:\s+(?<value>\w+))? \s*$/x
    end

    def execute
      key, value = @match[:setting], @match[:value]
      return print SetCommand.help(nil) if key.nil? && value.nil?

      full_key = Setting.find(key)
      return print "Unknown setting :#{key}\n" unless full_key

      if !Setting.boolean?(full_key) && value.nil?
        return print "You must specifiy a value for setting :#{key}"
      elsif Setting.boolean?(full_key)
        value = get_onoff(value, key =~ /^no/ ? false : true)
      elsif Setting.integer?(full_key)
        value = get_int(value, full_key, 1, 300)
      end

      Setting[full_key.to_sym] = value

      return print Setting.settings[full_key.to_sym].to_s
    end

    def get_onoff(arg, default)
      return default if arg.nil?
      case arg
      when '1', 'on'
        return true
      when '0', 'off'
        return false
      else
        print "Expecting 'on', 1, 'off', or 0. Got: #{arg.to_s}.\n"
        raise RuntimeError
      end
    end

    class << self
      def names
        %w(set)
      end

      def description
        %{Modifies parts of byebug environment. Boolean values take on, off, 1
          or 0. You can see these environment settings with the "show" command.}
      end
    end
  end

end
