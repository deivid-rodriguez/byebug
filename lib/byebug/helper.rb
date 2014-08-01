module Byebug
  module ParseFunctions
    Position_regexp = '(?:(\d+)|(.+?)[:.#]([^.:\s]+))'

    #
    # Parse 'str' of command 'cmd' as an integer between min and max. If either
    # min or max is nil, that value has no bound.
    #
    def get_int(str, cmd, min = nil, max = nil, default = 1)
      unless str
        return default if default
        print "You need to specify an argument for \"#{cmd}\"\n"
        return nil
      end

      begin
        int = Integer(str)
        if min and int < min
          print "\"#{cmd}\" argument \"#{str}\" needs to be at least #{min}\n"
          return nil
        elsif max and int > max
          print "\"#{cmd}\" argument \"#{str}\" needs to be at most #{max}\n"
          return nil
        end
        return int
      rescue
        print "\"#{cmd}\" argument \"#{str}\" needs to be a number\n"
        return nil
      end
    end

    #
    # Gets all lines in a source code file
    #
    def get_lines(filename)
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
    def get_line(filename, lineno)
      return nil unless lines = get_lines(filename)

      return lines[lineno-1]
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
