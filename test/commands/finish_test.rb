require 'test_helper'

module Byebug
  #
  # Tests +finish+ functionality when it needs to stop after method return
  # events.
  #
  class FinishAfterReturnTest < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test the +finish+ command
         4:    #
         5:    class #{example_class}
         6:      def a
         7:        b
         8:      end
         9:
        10:      def b
        11:        c
        12:        2
        13:      end
        14:
        15:      def c
        16:        d
        17:        3
        18:      end
        19:
        20:      def d
        21:        5
        22:      end
        23:    end
        24:
        25:    byebug
        26:
        27:    #{example_class}.new.a
        28:  end
      EOC
    end

    def test_finish_stops_after_current_single_line_frame_is_finished
      enter 'break 21', 'cont', 'finish'

      debug_code(program) { assert_equal 17, frame.line }
    end

    def test_finish_stops_after_current_multiline_frame_is_finished
      enter 'break 16', 'cont', 'finish'

      debug_code(program) { assert_equal 12, frame.line }
    end

    def test_finish_1_stops_after_current_frame_is_finished
      enter 'break 21', 'cont', 'finish 1'

      debug_code(program) { assert_equal 17, frame.line }
    end

    def test_finish_works_for_frame_numbers_higher_than_one
      enter 'break 21', 'cont', 'finish 2'

      debug_code(program) { assert_equal 12, frame.line }
    end

    def test_finish_behaves_consistenly_even_if_current_frame_has_been_changed
      enter 'break 21', 'cont', 'up', 'finish'

      debug_code(program) { assert_equal 12, frame.line }
    end

    def test_finish_shows_an_error_if_incorrect_frame_number_specified
      enter 'break 21', 'cont', 'finish foo'
      debug_code(program)

      check_error_includes '"finish" argument "foo" needs to be a number'
    end

    def test_finish_stays_at_the_same_line_if_incorrect_frame_number_specified
      enter 'break 21', 'cont', 'finish foo'

      debug_code(program) { assert_equal 21, frame.line }
    end

    def test_finish_does_not_stop_in_byebug_internal_frames
      enter 'break 21', 'cont', 'finish 4'

      debug_code(program) { assert_program_finished }
    end
  end

  #
  # Tests +finish+ functionality when it needs to stop before method return
  # events.
  #
  class FinishBeforeReturn < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test the +finish+ command
         4:    #
         5:    class #{example_class}
         6:      def a
         7:        b
         8:      end
         9:
        10:      def b
        11:        (1..10).map do |i|
        12:          i**2
        13:        end
        14:      end
        15:    end
        16:
        17:    byebug
        18:
        19:    #{example_class}.new.a
        20:  end
      EOC
    end

    def test_finish_0_works_in_simple_setups
      enter 'b 7', 'cont', 'finish 0'

      debug_code(program) { assert_equal 8, frame.line }
    end

    def test_finish_0_works_in_complicated_setups
      enter 'b 11', 'cont', 'finish 0'

      debug_code(program) { assert_equal 14, frame.line }
    end
  end
end
