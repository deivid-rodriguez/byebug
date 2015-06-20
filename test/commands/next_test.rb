require 'test_helper'

module Byebug
  #
  # Tests basic stepping behaviour.
  #
  class BasicNextTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test stepping.
         4:    #
         5:    class #{example_class}
         6:      def self.add_four(num)
         7:        byebug
         8:        num += 4
         9:        num += 2
        10:        num
        11:      end
        12:    end
        13:
        14:    res = #{example_class}.add_four(7)
        15:
        16:    res + 1
        17:  end
      EOC
    end

    def test_next_goes_to_the_next_line
      enter 'next'

      debug_code(program) { assert_location example_path, 9 }
    end

    def test_n_goes_to_the_next_line
      enter 'n'

      debug_code(program) { assert_location example_path, 9 }
    end

    def test_next_stays_in_current_frame_while_not_finished
      enter 'next 2'

      debug_code(program) { assert_location example_path, 10 }
    end

    def test_next_goes_up_a_frame_when_current_frame_finishes
      enter 'next 3'

      debug_code(program) { assert_equal 16, state.line }
    end

    def test_next_does_not_stop_at_byebug_internal_frames
      enter 'next 4'

      debug_code(program) { refute_match(/byebug.test.support/, state.file) }
    end
  end

  #
  # Test for See [#103](https://github.com/deivid-rodriguez/byebug/issues/103)
  #
  class NextWhenReturnInsideLoopInsideInitializeTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  byebug
         2:
         3:  module Byebug
         4:    #
         5:    # Toy class to test next.
         6:    #
         7:    class #{example_class}
         8:      def initialize
         9:        loop { return }
        10:      end
        11:    end
        12:
        13:    #{example_class}.new
        14:
        15:    puts 'Bye!'
        16:  end
      EOC
    end

    def test_next_works_return_inside_loop_inside_initialize
      skip unless RUBY_VERSION == '2.3.0'
      enter 'cont 13', 'next'

      debug_code(program) { assert_location example_path, 15 }
    end
  end

  #
  # Tests next behaviour in rescue clauses.
  #
  class NextRescueTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test stepping and rescue interaction.
         4:    #
         5:    class #{example_class}
         6:      def self.raise_from_c
         7:        unknown
         8:      rescue NameError
         9:        1
        10:      end
        11:
        12:      def self.raise_from_ruby
        13:        fails_badly
        14:      rescue
        15:        1
        16:      end
        17:
        18:      def self.fails_badly
        19:        fail 'booooooooooooooom'
        20:      end
        21:    end
        22:
        23:    byebug
        24:
        25:    #{example_class}.raise_from_c
        26:    #{example_class}.raise_from_ruby
        27:  end
      EOC
    end

    def test_next_steps_over_rescue_when_raising_from_c_method
      enter "break Byebug::#{example_class}.raise_from_c", 'cont', 'next 2'
      debug_code(program) { assert_equal 9, state.line }
    end

    def test_next_steps_over_rescue_when_raising_from_ruby_method
      enter "break Byebug::#{example_class}.raise_from_ruby", 'cont', 'next 2'
      debug_code(program) { assert_equal 15, state.line }
    end
  end

  #
  # Tests next behaviour in combination with backtrace commands.
  #
  class NextBacktracesTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
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
      EOC
    end

    def test_step_then_up_then_next_advances_in_the_upper_frame
      enter 'step', 'up', 'next'
      debug_code(program) { assert_equal 9, state.line }
    end
  end

  #
  # Tests next when execution should not stop at the same "stack size level"
  #
  class TestNextGoingUpFrames < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test cases where next should not stay in frame
         4:    #
         5:    class #{example_class}
         6:      def finite_loop
         7:        n = 0
         8:        loop do
         9:          n = inc(n)
        10:          break if n == 2
        11:          n = inc(n)
        12:        end
        13:      end
        14:
        15:      def inc(n)
        16:        if n == 2
        17:          n
        18:        else
        19:          n + 1
        20:        end
        21:      end
        22:    end
        23:
        24:    byebug
        25:
        26:    #{example_class}.new.finite_loop
        27:  end
      EOC
    end

    def test_next_goes_up_a_frame_if_current_frame_finishes
      enter 'cont 19', 'next'
      debug_code(program) { assert_equal 10, state.line }
    end

    def test_next_does_not_enter_other_frames_of_the_same_size
      enter 'b 19', 'cont', 'cont', 'next'
      debug_code(program) { assert_equal 9, state.line }
    end
  end
end
