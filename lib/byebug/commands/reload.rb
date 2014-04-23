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

    def regexp
      /^\s* r(?:eload)? \s*$/x
    end

    def execute
      Byebug.source_reload
      print "Source code is reloaded. Automatic reloading is "   \
            "#{Setting[:autoreload] ? 'on' : 'off'}.\n"
    end

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
