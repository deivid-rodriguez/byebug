module Byebug

  # Implements byebug "reload" command.
  class ReloadCommand < Command
    self.allow_in_control = true

    register_setting_get(:reload_source_on_change) do
      Byebug.class_variable_get(:@@reload_source_on_change)
    end

    register_setting_set(:reload_source_on_change) do |value|
      Byebug.class_variable_set(:@@reload_source_on_change, value)
    end
    Command.settings[:reload_source_on_change] = true

    def regexp
      /^\s*r(?:eload)?$/
    end

    def execute
      Byebug.source_reload
      print "Source code is reloaded. Automatic reloading is #{source_reloading}.\n"
    end

    private

    def source_reloading
      Command.settings[:reload_source_on_change] ? 'on' : 'off'
    end

    class << self
      def names
        %w(reload)
      end

      def description
        %{
          r[eload]\tforces source code reloading
        }
      end
    end
  end
end
