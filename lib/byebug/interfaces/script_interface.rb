module Byebug
  #
  # Interface class for command execution from script files.
  #
  class ScriptInterface < Interface
    def initialize(file, out, verbose = false)
      super()
      @file = file.respond_to?(:gets) ? file : open(file)
      @out, @verbose = out, verbose
    end

    def read_command(_prompt)
      while (result = @file.gets)
        puts "# #{result}" if @verbose
        next if result =~ /^\s*#/
        next if result.strip.empty?
        return result.chomp
      end
    end

    def confirm(_prompt)
      'y'
    end

    def puts(message)
      @out.printf(message)
    end

    def close
      @file.close
    end
  end
end
