module Byebug
  #
  # Interface class for command execution from script files.
  #
  class ScriptInterface < Interface
    def initialize(file, verbose = false)
      super()
      @input = File.open(file)
      @output = verbose ? STDOUT : StringIO.new
      @error = verbose ? STDERR : StringIO.new
    end

    def read_command(_prompt)
      readline(_prompt, false)
    end

    def close
      input.close
    end

    def readline(prompt, hist)
      while (result = input.gets)
        output.puts "# #{result}"
        next if result =~ /^\s*#/
        return result.chomp
      end
    end
  end
end
