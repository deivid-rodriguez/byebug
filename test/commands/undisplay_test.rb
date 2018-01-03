# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests undisplay command used to stop periodically displaying expressions.
  #
  class UndisplayTest < TestCase
    def program
      strip_line_numbers <<-RUBY
        1:  module Byebug
        2:    d = 0
        3:
        4:    byebug
        5:
        6:    d += 3
        7:    d + 6
        8:  end
      RUBY
    end

    def test_asks_for_confirmation
      enter "display d", "display d + 1", "undisplay"
      debug_code(program) { clear_displays }

      check_output_includes "Clear all expressions? (y/n)"
    end

    def test_removes_all_expressions_from_list_if_confirmed
      enter "display d", "display d + 1", "undisplay", "y", "next"

      debug_code(program) do
        assert_equal [[false, "d"], [false, "d + 1"]], Byebug.displays
        clear_displays
      end

      check_output_doesnt_include "1: d = 3", "2: d + 1 = 4"
    end

    def test_does_not_remove_all_expressions_from_list_unless_confirmed
      enter "display d", "display d + 1", "undisplay", "n", "display"

      debug_code(program) do
        assert_equal [[true, "d"], [true, "d + 1"]], Byebug.displays
        clear_displays
      end

      check_output_includes "1: d = 0", "2: d + 1 = 1"
    end

    def test_marks_specific_expression_from_list_as_inactive
      enter "display d", "display d + 1", "undisplay 1"

      debug_code(program) do
        assert_equal [[nil, "d"], [true, "d + 1"]], Byebug.displays
        clear_displays
      end
    end

    def test_displays_only_the_active_position
      enter "display d", "display d + 1", "undisplay 1", "next"
      debug_code(program) { clear_displays }

      check_output_includes "2: d + 1 = 4"
      check_output_doesnt_include "1: d = 3"
    end

    def test_disable_display_removes_the_expression_from_display_list
      enter "display d", "disable display 1"

      debug_code(program) do
        assert_equal [[false, "d"]], Byebug.displays
        clear_displays
      end
    end

    def test_disable_display_shows_an_error_if_no_displays_are_set
      enter "disable display 1"
      debug_code(program)

      check_error_includes "No display expressions have been set"
    end

    def test_disable_display_shows_an_error_if_theres_no_such_display_position
      enter "display d", "disable display 4"
      debug_code(program) { clear_displays }

      check_error_includes \
        '"disable display" argument "4" needs to be at most 1'
    end

    def test_enable_display_set_display_flag_to_true_in_display_list
      enter "display d", "disable display 1", "enable display 1"

      debug_code(program) do
        assert_equal [[true, "d"]], Byebug.displays
        clear_displays
      end
    end
  end
end
