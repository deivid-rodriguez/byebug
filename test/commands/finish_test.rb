module Byebug
  class FinishExample
    def a
      b
    end

    def b
      c
      2
    end

    def c
      d
      3
    end

    def d
      5
    end
  end

  class FinishTestCase < TestCase
    def setup
      @example = -> do
        byebug
        FinishExample.new.a
      end

      super
      enter 'break 18', 'cont'
    end

    def test_finish_stops_after_current_frame_is_finished
      enter 'finish'
      debug_proc(@example) { assert_equal 14, state.line }
    end

    def test_finish_0_stops_before_current_frame_finishes
      enter 'finish 0'
      debug_proc(@example) { assert_equal 19, state.line }
    end

    def test_finish_1_stops_after_current_frame_is_finished
      enter 'finish 1'
      debug_proc(@example) { assert_equal 14, state.line }
    end

    def test_finish_works_for_frame_numbers_higher_than_one
      enter 'finish 2'
      debug_proc(@example) { assert_equal 9, state.line }
    end

    def test_finish_behaves_consistenly_even_if_current_frame_has_been_changed
      enter 'up', 'finish'
      debug_proc(@example) { assert_equal 9, state.line }
    end

    def test_finish_shows_an_error_if_incorrect_frame_number_specified
      enter 'finish foo'
      debug_proc(@example)
      check_error_includes '"finish" argument "foo" needs to be a number'
    end

    def test_finish_stays_at_the_same_line_if_incorrect_frame_number_specified
      enter 'finish foo'
      debug_proc(@example) { assert_equal 18, state.line }
    end

    def test_finish_does_not_stop_in_byebug_internal_frames
      enter 'finish 4'
      debug_proc(@example) { refute_match(/byebug.test.support/, state.file) }
    end
  end
end
