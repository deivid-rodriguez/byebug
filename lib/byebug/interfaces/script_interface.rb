require 'io/console'

module Byebug
  #
  # Interface class for command execution from script files.
  #
  class ScriptInterface < Interface
    def initialize(file, verbose = false)
      super()
      @input = File.open(file)
      @verbose = verbose
      @error = IO.console
      @output = verbose ? @error : File.open(File::NULL, File::WRONLY)
    end

    def read_command(prompt)
      readline(prompt, false)
    end

    def close
      input.close
      @output.close
    end

    def readline(*)
      while (result = input.gets)
        output.puts "+ #{result}" if @verbose
        next if result =~ /^\s*#/
        return result.chomp
      end
    end
  end
end
