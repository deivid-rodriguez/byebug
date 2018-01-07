# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests launching new debuggers from byebug's prompt
  #
  class SubdebuggersTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:   #
         3:   # Toy class to test subdebuggers inside evaluation prompt
         4:   #
         5:   class #{example_class}
         6:     def self.a
         7:       byebug
         8:     end
         9:   end
        10:
        11:   byebug
        12:
        13:   "Bye!"
        14:  end
      RUBY
    end

    def test_subdebugger_stops_at_correct_point_when_invoked_through_byebug_call
      enter "debug #{example_class}.a"

      debug_code(program) { assert_equal 8, frame.line }
    end

    def test_subdebugger_stops_at_correct_point_when_invoked_from_breakpoint
      enter "break #{example_class}.a", "debug #{example_class}.a"

      if RUBY_VERSION >= "2.5.0"
        debug_code(program) { assert_equal 7, frame.line }
      else
        debug_code(program) { assert_equal 6, frame.line }
      end
    end

    def test_subdebugger_goes_back_to_previous_debugger_after_continue
      enter "debug #{example_class}.a", "continue"

      debug_code(program) { assert_equal 13, frame.line }
    end
  end
end
