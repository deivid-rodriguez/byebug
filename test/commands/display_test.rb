module Byebug
  #
  # Tests displaying values of expressions on every stop.
  #
  class DisplayTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    d = 0
        3:
        4:    byebug
        5:
        6:    d += 3
        7:    d + 6
        8:  end
      EOC
    end

    def test_shows_expressions
      enter 'display d + 1'
      debug_code(program)
      check_output_includes '1: d + 1 = 1'
    end

    def test_works_when_using_a_shortcut
      enter 'disp d + 1'
      debug_code(program)
      check_output_includes '1: d + 1 = 1'
    end

    def test_saves_displayed_expressions
      enter 'display d + 1'
      debug_code(program) { assert_equal [[true, 'd + 1']], state.display }
    end

    def test_displays_all_expressions_available
      enter 'display d', 'display d + 1', 'display'
      debug_code(program)
      check_output_includes '1: d = 0', '2: d + 1 = 1'
    end
  end
end
