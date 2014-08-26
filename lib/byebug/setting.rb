module Byebug
  #
  # Parent class for all byebug settings.
  #
  class Setting
    attr_accessor :value

    DEFAULT = false

    def initialize
      @value = self.class::DEFAULT
    end

    def self.settings
      @settings ||= {}
    end

    def self.[](name)
      settings[name].value
    end

    def self.[]=(name, value)
      settings[name].value = value
    end

    def self.boolean?(name)
      key = (name =~ /^no/ ? name[2..-1] : name).to_sym
      settings[key].boolean?
    end

    def self.integer?(name)
      settings[name.to_sym].integer?
    end

    def boolean?
      [true, false].include?(value)
    end

    def integer?
      Integer(value) ? true : false
    rescue ArgumentError
      false
    end

    def self.exists?(name)
      key = (name =~ /^no/ ? name[2..-1] : name).to_sym
      boolean?(key) ? settings.include?(key) : settings.include?(name.to_sym)
    end

    def self.load
      Dir.glob(File.expand_path('../settings/*.rb', __FILE__)).each do |file|
        require file
      end
      Byebug.constants.grep(/[a-z]Setting/).map do |name|
        setting = Byebug.const_get(name).new
        settings[setting.to_sym] = setting
      end
    end

    def self.find(shortcut)
      abbr = shortcut =~ /^no/ ? shortcut[2..-1] : shortcut
      matches = settings.select do |key, value|
        value.boolean? ? key =~ /#{abbr}/ : key =~ /#{shortcut}/
      end
      matches.size == 1 ? matches.keys.first : nil
    end

    def self.help_all
      output = "  List of settings supported in byebug:\n  --\n"
      width = settings.keys.max_by(&:size).size
      settings.values.each do |sett|
        output << format("  %-#{width}s -- %s\n", sett.to_sym, sett.banner)
      end
      output + "\n"
    end

    def self.help(cmd, subcmd)
      if subcmd
        camelized = subcmd.split('_').map { |w| w.capitalize }.join
        setting = Byebug.const_get("#{camelized}Setting").new
        <<-EOH.gsub(/^ {8}/, '')

          #{cmd} #{setting.to_sym} <value>

          #{setting.banner}.

        EOH
      else
        command = Byebug.const_get("#{cmd.capitalize}Command")
        command.description + help_all
      end
    end

    def help
      "\n  #{banner}.\n\n"
    end

    def to_sym
      name = self.class.name.gsub(/^Byebug::/, '').gsub(/Setting$/, '')
      name.gsub(/(.)([A-Z])/, '\1_\2').downcase.to_sym
    end

    def to_s
      "#{to_sym} is #{value ? 'on' : 'off'}\n"
    end
  end

  Setting.load
end
