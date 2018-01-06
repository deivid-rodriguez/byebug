# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests commands which show frames
  #
  class FrameTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test backtraces.
         4:    #
         5:    class #{example_class}
         6:      def initialize(letter)
         7:        @letter = encode(letter)
         8:      end
         9:
        10:      def encode(str)
        11:        integerize(str + "x") + 5
        12:      end
        13:
        14:      def integerize(str)
        15:        byebug
        16:        str.ord
        17:      end
        18:    end
        19:
        20:    frame = #{example_class}.new("f")
        21:
        22:    frame
        23:  end
      RUBY
    end

    def test_frame_moves_to_a_specific_frame
      enter "frame 2"

      debug_code(program) { assert_equal 7, frame.line }
    end

    def test_frame_autolists_new_source_location_when_autolist_enabled
      with_setting :autolist, true do
        enter "frame 2"
        debug_code(program)

        check_output_includes "=>  7:       @letter = encode(letter)"
      end
    end

    def test_frame_does_not_autolist_new_source_location_when_autolist_disabled
      with_setting :autolist, false do
        enter "frame 2"
        debug_code(program)

        check_output_doesnt_include "=>  7:       @letter = encode(letter)"
      end
    end

    def test_frame_prints_the_callstack_when_called_without_arguments
      enter "up", "frame"
      debug_code(program)

      check_output_includes(
        /--> #1  .*encode\(str#String\)\s* at .*#{example_path}:11/
      )
    end

    def test_frame_0_sets_frame_to_the_first_one
      enter "up", "frame 0"

      debug_code(program) { assert_equal 16, frame.line }
    end

    def test_frame_minus_one_sets_frame_to_the_last_one
      enter "frame -1"

      debug_code(program) { assert_location example_path, 1 }
    end

    def test_frame_cannot_navigate_to_c_frames
      enter "frame 3"
      debug_code(program)

      check_error_includes "Can't navigate to c-frame"
    end
  end
end
