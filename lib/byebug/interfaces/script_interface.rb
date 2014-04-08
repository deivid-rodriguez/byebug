module Byebug
  class ScriptInterface < Byebug::Interface
    def initialize(file, out, verbose=false)
      super()
      @file = file.respond_to?(:gets) ? file : open(file)
      @out, @verbose = out, verbose
    end

    def read_command(prompt)
      while result = @file.gets
        puts "# #{result}" if @verbose
        next if result =~ /^\s*#/
        next if result.strip.empty?
        return result.chomp
      end
    end

    def confirm(prompt)
      'y'
    end

    def print(*args)
      @out.printf(*args)
    end

    def close
      @file.close
    end
  end
end
