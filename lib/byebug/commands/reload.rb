module Byebug

  module ReloadFunctions
    def getlines(file, line)
      unless (lines = SCRIPT_LINES__[file]) and lines != true
        Tracer::Single.get_line(file, line) if File.exist?(file)
        lines = SCRIPT_LINES__[file]
        lines = nil if lines == true
      end
      lines
    end
  end

  # Implements byebug "reload" command.
  class ReloadCommand < Command
    self.allow_in_control = true
    self.allow_in_post_mortem = false

    register_setting_get(:autoreload) do
      Byebug.class_variable_get(:@@autoreload)
    end

    register_setting_set(:autoreload) do |value|
      Byebug.class_variable_set(:@@autoreload, value)
    end
    Command.settings[:autoreload] = true

    def regexp
      /^\s* r(?:eload)? \s*$/x
    end

    def execute
      Byebug.source_reload
      print "Source code is reloaded. Automatic reloading is "   \
            "#{Command.settings[:autoreload] ? 'on' : 'off'}.\n"
    end

    private

    class << self
      def names
        %w(reload)
      end

      def description
        %{r[eload]\tforces source code reloading}
      end
    end
  end
end
