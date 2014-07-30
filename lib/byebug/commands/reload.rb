module Byebug
  module ReloadFunctions
    #
    # Gets all lines in a source code file
    #
    def getlines(filename)
      return nil unless File.exist?(filename)

      unless lines = SCRIPT_LINES__[filename]
        lines = File.readlines(filename) rescue []
        SCRIPT_LINES__[filename] = lines
      end

      return lines
    end

    #
    # Gets a single line in a source code file
    #
    def getline(filename, lineno)
      return nil unless lines = getlines(filename)

      return lines[lineno-1]
    end
  end

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
