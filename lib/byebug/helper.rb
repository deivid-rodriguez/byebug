module Byebug

  module ParseFunctions
    Position_regexp = '(?:(\d+)|(.+?)[:.#]([^.:\s]+))'

    # Parse 'str' of command 'cmd' as an integer between
    # min and max. If either min or max is nil, that
    # value has no bound.
    def get_int(str, cmd, min=nil, max=nil, default=1)
      return default unless str
      begin
        int = Integer(str)
        if min and int < min
          print "\"#{cmd}\" argument \"#{str}\" needs to be at least #{min}.\n"
          return nil
        elsif max and int > max
          print "\"#{cmd}\" argument \"#{str}\" needs to be at most #{max}.\n"
          return nil
        end
        return int
      rescue
        print "\"#{cmd}\" argument \"#{str}\" needs to be a number.\n"
        return nil
      end
    end

    # Return true if arg is 'on' or 1 and false arg is 'off' or 0.
    # Any other value raises RuntimeError.
    def get_onoff(arg, default=nil, print_error=true)
      if arg.nil? or arg == ''
        if default.nil?
          if print_error
            print "Expecting 'on', 1, 'off', or 0. Got nothing.\n"
            raise RuntimeError
          end
          return default
        end
      end
      case arg.downcase
      when '1', 'on'
        return true
      when '0', 'off'
        return false
      else
        if print_error
          print "Expecting 'on', 1, 'off', or 0. Got: #{arg.to_s}.\n"
          raise RuntimeError
        end
      end
    end

    # Return 'on' or 'off' for supplied parameter. The parameter should
    # be true, false or nil.
    def show_onoff(bool)
      if not [TrueClass, FalseClass, NilClass].member?(bool.class)
        return "??"
      end
      return bool ? 'on' : 'off'
    end

    # Return true if code is syntactically correct for Ruby.
    def syntax_valid?(code)
      eval("BEGIN {return true}\n#{code}", nil, "", 0)
    rescue Exception
      false
    end

  end
end
