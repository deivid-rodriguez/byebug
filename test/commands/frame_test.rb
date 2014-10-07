module Byebug
  #
  # Tests commands which deal with backtraces.
  #
  class FrameTestCase < TestCase
    def program
      strip_line_numbers <<-EOP
         1:  module Byebug
         2:    #
         3:    # Toy class to test backtraces.
         4:    #
         5:    class TestExample
         6:      def initialize(letter)
         7:        @letter = encode(letter)
         8:      end
         9:
        10:      def encode(str)
        11:        integerize(str + 'x') + 5
        12:      end
        13:
        14:      def integerize(str)
        15:        byebug
        16:        str.ord
        17:      end
        18:    end
        19:
        20:    frame = TestExample.new('f')
        21:
        22:    frame
        23:  end
      EOP
    end

    def test_up_moves_up_in_the_callstack
      enter 'up'
      debug_code(program) { assert_equal 11, state.line }
    end

    def test_up_moves_up_in_the_callstack_a_specific_number_of_frames
      enter 'up 2'
      debug_code(program) { assert_equal 7, state.line }
    end

    def test_down_moves_down_in_the_callstack
      enter 'up', 'down'
      debug_code(program) { assert_equal 16, state.line }
    end

    def test_down_moves_down_in_the_callstack_a_specific_number_of_frames
      enter 'up 3', 'down 2'
      debug_code(program) { assert_equal 11, state.line }
    end

    def test_frame_moves_to_a_specific_frame
      enter 'frame 2'
      debug_code(program) { assert_equal 7, state.line }
    end

    def test_frame_prints_the_callstack_when_called_without_arguments
      enter 'up', 'frame'
      debug_code(program)
      check_output_includes(
        /--> #1  .*encode\(str#String\)\s* at .*#{example_path}:11/)
    end

    def test_frame_0_sets_frame_to_the_first_one
      enter 'up', 'frame 0'
      debug_code(program) { assert_equal 16, state.line }
    end

    def test_frame_minus_one_sets_frame_to_the_last_one
      enter 'frame -1'
      debug_code(program) { assert_equal example_path, state.file }
    end

    def test_down_does_not_move_if_frame_number_to_too_low
      enter 'down'
      debug_code(program) { assert_equal 16, state.line }
      check_error_includes "Can't navigate beyond the newest frame"
    end

    def test_up_does_not_move_if_frame_number_to_too_high
      enter 'up 100'
      debug_code(program) { assert_equal 16, state.line }
      check_error_includes "Can't navigate beyond the oldest frame"
    end

    def test_where_displays_current_backtrace_with_fullpaths
      enter 'set fullpath', 'where'
      debug_code(program)
      full_example = File.expand_path(example_path)
      check_output_includes(
        /--> #0  .*integerize\(str#String\)\s* at #{full_example}:16/,
            /#1  .*encode\(str#String\)\s* at #{full_example}:11/,
            /#2  .*initialize\(letter#String\)\s* at #{full_example}:7/,
            /ͱ-- #3  Class\.new\(\*args\)\s* at #{full_example}:20/,
            /#4  <module:Byebug>\s* at #{full_example}:20/,
            /#5  <top \(required\)>\s* at #{full_example}:1/)
    end

    def test_where_displays_current_backtrace_w_shorpaths_if_fullpath_disabled
      enter 'set nofullpath', 'where'
      debug_code(program)
      check_output_includes(
        /--> #0  .*integerize\(str#String\)\s* at .*#{example_path}:16/,
        /#1  .*encode\(str#String\)\s* at .*#{example_path}:11/,
        /#2  .*initialize\(letter#String\)\s* at .*#{example_path}:7/,
        /ͱ-- #3  Class\.new\(\*args\) at .*#{example_path}:20/,
        /#4  <module:Byebug> at .*#{example_path}:20/,
        /#5  <top \(required\)> at .*#{example_path}:1/)
    end

    def test_where_displays_backtraces_using_long_callstyle
      enter 'set callstyle long', 'where'
      debug_code(program)
      kl = 'Byebug::TestExample'
      check_output_includes(
        /--> #0  #{kl}.integerize\(str#String\)\s* at #{example_fullpath}:16/,
        /#1  #{kl}.encode\(str#String\)\s* at #{example_fullpath}:11/,
        /#2  #{kl}.initialize\(letter#String\)\s* at #{example_fullpath}:7/,
        /ͱ-- #3  Class\.new\(\*args\)\s* at #{example_fullpath}:20/,
        /#4  <module:Byebug>\s* at #{example_fullpath}:20/,
        /#5  <top \(required\)>\s* at #{example_fullpath}:1/)
    end

    def test_where_displays_backtraces_using_short_callstyle
      enter 'set callstyle short', 'where'
      debug_code(program)
      check_output_includes(
        /--> #0  integerize\(str\)\s* at #{example_fullpath}:16/,
        /#1  encode\(str\)\s* at #{example_fullpath}:11/,
        /#2  initialize\(letter\)\s* at #{example_fullpath}:7/,
        /ͱ-- #3  new\(\*args\)\s* at #{example_fullpath}:20/,
        /#4  <module:Byebug>\s* at #{example_fullpath}:20/,
        /#5  <top \(required\)>\s* at #{example_fullpath}:1/)
    end

    def test_up_skips_c_frames
      enter 'up 2', 'frame'
      debug_code(program)
      check_output_includes(
        /--> #2.*initialize\(letter#String\)\s* at .*#{example_path}:7/)
    end

    def test_down_skips_c_frames
      enter 'up 3', 'down', 'frame'
      debug_code(program)
      check_output_includes(
        /--> #2  .*initialize\(letter#String\)\s* at .*#{example_path}:7/)
    end

    def test_frame_cannot_navigate_to_c_frames
      enter 'frame 3'
      debug_code(program)
      check_error_includes "Can't navigate to c-frame"
    end

    def test_eval_works_properly_when_moving_through_the_stack
      enter 'p str', 'up', 'p str', 'up'
      debug_code(program)
      check_output_includes '"fx"', '"f"'
    end
  end
end
