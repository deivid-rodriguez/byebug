module Byebug
  class DisplayTestCase < TestCase
    def setup
      @example = -> do
        d = 0
        byebug
        d = d + 3
        d = d + 6
      end

      super
    end

    def test_shows_expressions
      enter 'display d + 1'
      debug_proc(@example)
      check_output_includes '1: d + 1 = 1'
    end

    def test_works_when_using_a_shortcut
      enter 'disp d + 1'
      debug_proc(@example)
      check_output_includes '1: d + 1 = 1'
    end

    def test_saves_displayed_expressions
      enter 'display d + 1'
      debug_proc(@example) { assert_equal [[true, 'd + 1']], state.display }
    end

    def test_displays_all_expressions_available
      enter 'display d', 'display d + 1', 'display'
      debug_proc(@example)
      check_output_includes '1: d = 0', '2: d + 1 = 1'
    end
  end
end
