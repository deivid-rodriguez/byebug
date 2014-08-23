module Byebug
  class FrameExample
    def initialize(f)
      @f = f
    end

    def a
      b
    end

    def b
      c
      2
    end

    def c
      d('a')
      3
    end

    def d(e)
      4
    end
  end

  class FrameTestCase < TestCase
    def setup
      @example = -> do
        byebug
        fr_ex = FrameExample.new('f')
        fr_ex.a()
      end

      super
    end

    def test_up_moves_up_in_the_callstack
      enter 'break 22', 'cont', 'up'
      debug_proc(@example) { assert_equal 17, state.line }
    end

    def test_up_moves_up_in_the_callstack_a_specific_number_of_frames
      enter 'break 22', 'cont', 'up 2'
      debug_proc(@example) { assert_equal 12, state.line }
    end

    def test_down_moves_down_in_the_callstack
      enter 'break 22', 'cont', 'up', 'down'
      debug_proc(@example) { assert_equal 22, state.line }
    end

    def test_down_moves_down_in_the_callstack_a_specific_number_of_frames
      enter 'break 22', 'cont', 'up 3', 'down 2'
      debug_proc(@example) { assert_equal 17, state.line }
    end

    def test_frame_moves_to_a_specific_frame
      enter 'break 22', 'cont', 'frame 2'
      debug_proc(@example) { assert_equal 12, state.line }
    end

    def test_frame_prints_the_callstack_when_called_without_arguments
      enter 'break 22', 'cont', 'up', 'frame'
      debug_proc(@example)
      check_output_includes(/#1  Byebug::FrameExample\.c\s+at #{__FILE__}:17/)
    end

    def test_frame_0_sets_frame_to_the_first_one
      enter 'break 22', 'cont', 'up', 'frame 0'
      debug_proc(@example) { assert_equal 22, state.line }
    end

    def test_frame_minus_one_sets_frame_to_the_last_one
      enter 'break 22', 'cont', 'frame -1'
      debug_proc(@example) { assert_match 'frame_test.rb', state.file }
    end

    def test_down_does_not_move_if_frame_number_to_too_low
      enter 'break 22', 'cont', 'down'
      debug_proc(@example) { assert_equal 22, state.line }
      check_error_includes "Can't navigate beyond the newest frame"
    end

    def test_up_does_not_move_if_frame_number_to_too_high
      enter 'break 22', 'cont', 'up 100'
      debug_proc(@example) { assert_equal 22, state.line }
      check_error_includes "Can't navigate beyond the oldest frame"
    end

    def test_where_displays_current_backtrace_with_fullpaths
      enter 'break 22', 'cont', 'where'
      debug_proc(@example)
      check_output_includes(
        /--> #0  Byebug::FrameExample\.d\(e#String\)\s+at #{__FILE__}:22/,
            /#1  Byebug::FrameExample\.c\s+at #{__FILE__}:17/,
            /#2  Byebug::FrameExample\.b\s+at #{__FILE__}:12/,
            /#3  Byebug::FrameExample\.a\s+at #{__FILE__}:8/)
    end

    def test_where_displays_current_backtrace_w_shorpaths_if_fullpath_disabled
      enter 'break 22', 'cont', 'set nofullpath', 'where'
      debug_proc(@example)
      path = File.basename(__FILE__)
      check_output_includes(
        /--> #0  Byebug::FrameExample\.d\(e#String\)\s+at \.\.\..*#{path}:22/,
            /#1  Byebug::FrameExample\.c\s+at \.\.\..*#{path}:17/,
            /#2  Byebug::FrameExample\.b\s+at \.\.\..*#{path}:12/,
            /#3  Byebug::FrameExample\.a\s+at \.\.\..*#{path}:8/)
    end

    def test_where_displays_backtraces_using_long_callstyle
      enter 'break 22', 'cont', 'set callstyle long', 'where'
      debug_proc(@example)
      check_output_includes(
        /--> #0  Byebug::FrameExample\.d\(e#String\)\s+at #{__FILE__}:22/,
            /#1  Byebug::FrameExample\.c\s+at #{__FILE__}:17/,
            /#2  Byebug::FrameExample\.b\s+at #{__FILE__}:12/,
            /#3  Byebug::FrameExample\.a\s+at #{__FILE__}:8/)
    end

    def test_where_displays_backtraces_using_short_callstyle
      enter 'break 22', 'cont', 'set callstyle short', 'where'
      debug_proc(@example)
      check_output_includes(/--> #0  d\(e\)\s+at #{__FILE__}:22/,
                                /#1  c\s+at #{__FILE__}:17/,
                                /#2  b\s+at #{__FILE__}:12/,
                                /#3  a\s+at #{__FILE__}:8/)
    end

    def test_where_marks_c_frames_when_printing_the_callstack
      enter 'break 4', 'cont', 'where'
      debug_proc(@example)
      path = __FILE__
      check_output_includes(
        /--> #0  Byebug::FrameExample.initialize\(f#String\)\s+at #{path}:4/,
            /ͱ-- #1  Class.new\(\*args\)\s+at #{__FILE__}:30/,
            /#2  block in Byebug::FrameTestCase.setup\s+at #{path}:30/)
    end

    def test_up_skips_c_frames
      enter 'break 4', 'cont', 'where', 'up', 'where'
      debug_proc(@example)
      check_output_includes(
        /--> #2  block in Byebug::FrameTestCase.setup\s+at #{__FILE__}:30/)
    end

    def test_down_skips_c_frames
      enter 'break 4', 'cont', 'up', 'down', 'eval f'
      debug_proc(@example)
      check_output_includes '"f"'
    end

    def test_frame_cannot_navigate_to_c_frames
      enter 'break 4', 'cont', 'frame 1'
      debug_proc(@example)
      check_error_includes "Can't navigate to c-frame"
    end
  end

  class DeepFrameExample
    def a
      z = 1
      z += b
    end

    def b
      z = 2
      z += c
    end

    def c
      z = 3
      byebug
      z += d('a')
    end

    def d(e)
      4
    end
  end

  class DeepFrameTestCase < TestCase
    def setup
      @deep_example = -> do
        DeepFrameExample.new.a
      end

      super
      enter 'break 178', 'cont'
    end

    def test_where_correctly_prints_the_backtrace
      enter 'where'
      debug_proc(@deep_example)
      check_output_includes(
        /--> #0  Byebug::DeepFrameExample\.d\(e#String\)\s+at #{__FILE__}:178/,
            /#1  Byebug::DeepFrameExample\.c\s+at #{__FILE__}:174/,
            /#2  Byebug::DeepFrameExample\.b\s+at #{__FILE__}:168/,
            /#3  Byebug::DeepFrameExample\.a\s+at #{__FILE__}:163/)
    end

    def test_up_moves_up_in_the_callstack
      enter 'up'
      debug_proc(@deep_example) { assert_equal 174, state.line }
    end

    def test_down_moves_down_in_the_callstack
      enter 'up', 'down'
      debug_proc(@deep_example) { assert_equal 178, state.line }
    end

    def test_frame_moves_to_a_specific_frame
      enter 'frame 2'
      debug_proc(@deep_example) { assert_equal 168, state.line }
    end

    def test_eval_works_properly_when_moving_through_the_stack
      enter 'p z', 'up', 'p z', 'up', 'p z'
      debug_proc(@deep_example)
      check_output_includes 'nil', '3', '2'
    end
  end
end
