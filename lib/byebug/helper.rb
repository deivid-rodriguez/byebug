module Byebug
  #
  # Miscelaneous Utilities
  #
  module MiscUtils
    #
    # Cross-platform way of finding an executable in the $PATH.
    # Borrowed from: http://stackoverflow.com/questions/2108727
    #
    def which(cmd)
      return File.expand_path(cmd) if File.exist?(cmd)

      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end

      nil
    end
  end

  #
  # Utilities for interaction with files
  #
  module FileFunctions
    #
    # Reads line number +lineno+ from file named +filename+
    #
    def get_line(filename, lineno)
      File.open(filename) do |f|
        f.gets until f.lineno == lineno - 1
        f.gets
      end
    end

    #
    # Returns the number of lines in file +filename+ in a portable,
    # one-line-at-a-time way.
    #
    def n_lines(filename)
      File.foreach(filename).reduce(0) { |a, _e| a + 1 }
    end
  end

  #
  # Utilities to assist command parsing
  #
  module ParseFunctions
    #
    # Parse 'str' of command 'cmd' as an integer between min and max. If either
    # min or max is nil, that value has no bound.
    #
    def get_int(str, cmd, min = nil, max = nil)
      if str !~ /\A[0-9]+\z/
        return nil, pr('parse.errors.int.not_number', cmd: cmd, str: str)
      end

      int = str.to_i
      if min && int < min
        return min, pr('parse.errors.int.too_low', cmd: cmd, str: str, min: min)
      elsif max && int > max
        return max, pr('parse.errors.int.too_high',
                       cmd: cmd, str: str, max: max)
      end

      int
    end

    #
    # Returns true if code is syntactically correct for Ruby.
    #
    def syntax_valid?(code)
      eval("BEGIN {return true}\n#{code}", nil, '', 0)
    rescue SyntaxError
      false
    end

    #
    # Returns the number of steps specified in <str> as an integer or 1 if <str>
    # is empty.
    #
    def parse_steps(str, cmd)
      return 1 unless str

      steps, err = get_int(str, cmd, 1)
      return nil, err unless steps

      steps
    end
  end
end
