# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests displaying values of expressions on every stop.
  #
  class DisplayTest < TestCase
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

    def test_shows_expressions
      enter "display d + 1"
      debug_code(program) { clear_displays }

      check_output_includes "1: d + 1 = 1"
    end

    def test_shows_undefined_expressions
      enter "display e"
      debug_code(program) { clear_displays }

      check_output_includes "1: e = (undefined)"
    end

    def test_saves_displayed_expressions
      enter "display d + 1"

      debug_code(program) do
        assert_equal [[true, "d + 1"]], Byebug.displays
        clear_displays
      end
    end

    def test_displays_all_expressions_available
      enter "display d", "display d + 1", "display"

      debug_code(program) { clear_displays }

      check_output_includes "1: d = 0", "2: d + 1 = 1"
    end
  end
end
