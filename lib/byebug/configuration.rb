require 'singleton'

module Byebug
  class Configuration
    include Singleton

    def settings
      @settings ||= {}
    end

    def [](name)
      raise "No such setting #{name}" unless settings.has_key?(name)

      settings[name][:getter].call
    end

    def []=(name, value)
      raise "No such setting #{name}" unless settings.has_key?(name)

      settings[name][:setter].call(value)
    end

    def register(name, default, getter = nil, setter = nil)
      settings[name] = { getter: getter || default_getter(name),
                         setter: setter || default_setter(name) }
      self[name] = default
    end

    private

      def default_setter(name)
        -> (value) { instance_variable_set("@#{name}", value) }
      end

      def default_getter(name)
        -> { instance_variable_get("@#{name}") }
      end
  end
end
