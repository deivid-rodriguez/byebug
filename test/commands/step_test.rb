# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests basic stepping behaviour.
  #
  class BasicSteppingTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test stepping.
         4:    #
         5:    class #{example_class}
         6:      def self.add_four(num)
         7:        num += 4
         8:        num
         9:      end
        10:    end
        11:
        12:    byebug
        13:
        14:    res = #{example_class}.add_four(7)
        15:
        16:    res + 1
        17:  end
      RUBY
    end

    def test_step_goes_to_the_next_statement
      enter "step"

      debug_code(program) { assert_equal 7, frame.line }
    end

    def test_s_goes_to_the_next_statement
      enter "s"

      debug_code(program) { assert_equal 7, frame.line }
    end
  end

  #
  # Tests step/next with arguments higher than one.
  #
  class MoreThanOneStepTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test advanced stepping.
         4:    #
         5:    class #{example_class}
         6:      def self.add_three(num)
         7:        byebug
         8:        2.times do
         9:          num += 1
        10:        end
        11:
        12:        num *= 2
        13:        num
        14:      end
        15:    end
        16:
        17:    res = #{example_class}.add_three(7)
        18:
        19:    res
        20:  end
      RUBY
    end

    def step_steps_into_blocks
      enter "step 2"

      debug_code(program) { assert_equal 9, frame.line }
    end

    def step_steps_out_of_blocks_when_done
      enter "step 3"

      debug_code(program) { assert_equal 12, frame.line }
    end
  end

  #
  # Tests step/next behaviour in combination with backtrace commands.
  #
  class SteppingBacktracesTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test the combination of "up" and "next" commands.
         4:    #
         5:    class #{example_class}
         6:      def a
         7:        byebug
         8:        r = b(c)
         9:        r + 1
        10:      end
        11:
        12:      def b(p)
        13:        r = 2
        14:        p + r
        15:      end
        16:
        17:      def c
        18:        s = 3
        19:        s + 2
        20:      end
        21:    end
        22:
        23:    #{example_class}.new.a
        24:  end
      RUBY
    end

    def test_step_then_up_then_steps_in_from_the_upper_frame
      enter "step", "up", "step"

      debug_code(program) { assert_equal 13, frame.line }
    end
  end
end
