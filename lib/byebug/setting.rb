require 'byebug/helper'

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

    def boolean?
      [true, false].include?(value)
    end

    def integer?
      Integer(value) ? true : false
    rescue ArgumentError
      false
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

    class << self
      include StringFunctions

      def settings
        @settings ||= {}
      end

      def [](name)
        settings[name].value
      end

      def []=(name, value)
        settings[name].value = value
      end

      def boolean?(name)
        key = (name =~ /^no/ ? name[2..-1] : name).to_sym
        settings[key].boolean?
      end

      def integer?(name)
        settings[name.to_sym].integer?
      end

      def exists?(name)
        key = (name =~ /^no/ ? name[2..-1] : name).to_sym
        boolean?(key) ? settings.include?(key) : settings.include?(name.to_sym)
      end

      def find(shortcut)
        abbr = shortcut =~ /^no/ ? shortcut[2..-1] : shortcut
        matches = settings.select do |key, value|
          value.boolean? ? key =~ /#{abbr}/ : key =~ /#{shortcut}/
        end
        matches.size == 1 ? matches.keys.first : nil
      end

      def help_all
        output = "  List of settings supported in byebug:\n  --\n"
        width = settings.keys.max_by(&:size).size
        settings.values.each do |sett|
          output << format("  %-#{width}s -- %s\n", sett.to_sym, sett.banner)
        end
        output + "\n"
      end

      def help(cmd, subcmd)
        unless subcmd
          command = Byebug.const_get("#{cmd.capitalize}Command")
          return command.description + help_all
        end

        setting = Byebug.const_get("#{camelize(subcmd)}Setting").new
        prettify <<-EOS
          #{cmd} #{setting.to_sym} <value>

          #{setting.banner}.
        EOS
      end
    end
  end
end
