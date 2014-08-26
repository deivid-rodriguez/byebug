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
      if str.nil?
        return nil, "You need to specify an argument for \"#{cmd}\""
      end

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
    # Gets all lines in a source code file
    #
    def get_lines(filename)
      return nil unless File.exist?(filename)

      lines = SCRIPT_LINES__[filename]
      unless lines
        lines = File.readlines(filename) rescue []
        SCRIPT_LINES__[filename] = lines
      end

      lines
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
  end
end
