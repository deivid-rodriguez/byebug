module Byebug
  #
  # Miscelaneous Utilities
  #
  module ParseFunctions
    #
    # Parse 'str' of command 'cmd' as an integer between min and max. If either
    # min or max is nil, that value has no bound.
    #
    def get_int(str, cmd, min = nil, max = nil)
      if str !~ /\A[0-9]+\z/
        return nil, "\"#{cmd}\" argument \"#{str}\" needs to be a number"
      end

      int = str.to_i
      if min && int < min
        return nil, "\"#{cmd}\" argument \"#{str}\" needs to be at least #{min}"
      elsif max && int > max
        return nil, "\"#{cmd}\" argument \"#{str}\" needs to be at most #{max}"
      end

      int
    end

    #
    # Fills SCRIPT_LINES__ entry for <filename> if not already filled.
    #
    def lines(filename)
      SCRIPT_LINES__[filename] ||= File.readlines(filename)
    end

    #
    # Gets all lines in a source code file
    #
    def get_lines(filename)
      return nil unless File.exist?(filename)

      lines(filename)
    end

    #
    # Gets a single line in a source code file
    #
    def get_line(filename, lineno)
      lines = get_lines(filename)
      return nil unless lines

      lines[lineno - 1]
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
