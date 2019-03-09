# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests for continue command
  #
  class SkipTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test continue_breakpoint command.
         4:    #
         5:    class #{example_class}
         6:      def factor(num)
         7:        i = 1
         8:        num.times do |new_number|
         9:          byebug
        10:          i *= new_number
        11:        end
        12:      end
        13:    end
        14:    c = 5
        15:
        16:    result = #{example_class}.new.factor(c)
        17:    "Result is: " + result.to_s
        18:  end
      RUBY
    end

    def test_continues_until_the_end_if_no_line_specified_and_no_breakpoints
      enter "break 17", "skip"

      debug_code(program) { assert_location example_path, 17 }
    end

    def test_works_in_abbreviated_mode_too
      enter "break 17", "sk"

      debug_code(program) { assert_location example_path, 17 }
    end
  end
end
