module Byebug
  #
  # Interface class for command execution from script files.
  #
  class ScriptInterface < Interface
    def initialize(file, verbose = false)
      super()
      @input = File.open(file)
      @output = verbose ? $stdout : StringIO.new
      @error = verbose ? $stderr : StringIO.new
    end

    def read_command(prompt)
      readline(prompt, false)
    end

    def close
      input.close
    end

    def readline(*)
      while (result = input.gets)
        output.puts "+ #{result}"
        next if result =~ /^\s*#/
        return result.chomp
      end
    end
  end
end
