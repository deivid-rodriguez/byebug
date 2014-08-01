module Byebug
  class ContinueExample
    def self.a(num)
      num + 4
    end
  end

  class ContinueTestCase < TestCase
    def setup
      @example = -> do
        byebug

        b = 5
        c = b + 5
        ContinueExample.a(c)
      end

      super
    end

    def test_continues_up_to_breakpoint_if_no_line_specified
      enter 'break 14', 'continue'
      debug_proc(@example) { assert_equal 14, state.line }
    end

    def test_works_in_abbreviated_mode_too
      enter 'break 14', 'cont'
      debug_proc(@example) { assert_equal 14, state.line }
    end

    def test_continues_up_to_the_specified_line
      enter 'cont 14'
      debug_proc(@example) { assert_equal 14, state.line }
    end

    def test_ignores_the_command_if_specified_line_is_not_valid
      enter 'cont 100'
      debug_proc(@example) { assert_equal 13, state.line }
    end

    def test_shows_error_if_specified_line_is_not_valid
      enter 'cont 100'
      debug_proc(@example)
      check_error_includes 'Line 100 is not a valid stopping point in file'
    end
  end
end
