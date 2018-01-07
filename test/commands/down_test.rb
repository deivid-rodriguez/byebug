# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests commands which deal with backtraces.
  #
  class DownTest < TestCase
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

    def test_down_moves_down_in_the_callstack
      enter "up", "down"

      debug_code(program) { assert_equal 16, frame.line }
    end

    def test_down_autolists_new_source_location_when_autolist_enabled
      with_setting :autolist, true do
        enter "up 2", "down"
        debug_code(program)

        check_output_includes '=> 11:       integerize(str + "x") + 5'
      end
    end

    def test_down_does_not_autolist_new_source_location_when_autolist_disabled
      with_setting :autolist, false do
        enter "up 2", "down"
        debug_code(program)

        check_output_doesnt_include '=> 11:       integerize(str + "x") + 5'
      end
    end

    def test_down_moves_down_in_the_callstack_a_specific_number_of_frames
      enter "up 3", "down 2"

      debug_code(program) { assert_equal 11, frame.line }
    end

    def test_down_skips_c_frames
      enter "up 3", "down", "frame"
      debug_code(program)

      check_output_includes(
        /--> #2  .*initialize\(letter#String\)\s* at .*#{example_path}:7/
      )
    end

    def test_down_does_not_move_if_frame_number_to_too_low
      enter "down"

      debug_code(program) { assert_equal 16, frame.line }
      check_error_includes "Can't navigate beyond the newest frame"
    end
  end
end
