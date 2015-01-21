module Byebug
  #
  # Tests enabling/disabling breakpoints.
  #
  class EnableDisableTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test breakpoints
         4:    #
         5:    class #{example_class}
         6:      def self.a(num)
         7:        num + 1
         8:      end
         9:
        10:      def b
        11:        3
        12:      end
        13:    end
        14:
        15:    y = 3
        16:
        17:    byebug
        18:
        19:    z = 5
        20:
        21:    #{example_class}.new.b
        22:    #{example_class}.a(y + z)
        23:  end
      EOC
    end

    def test_disabling_breakpoints_with_short_syntax_sets_enabled_to_false
      enter 'break 21', 'break 22', -> { "disable #{Breakpoint.first.id}" }

      debug_code(program) { assert_equal false, Breakpoint.first.enabled? }
    end

    def test_disabling_breakpoints_with_short_syntax_properly_ignores_them
      enter 'b 21', 'b 22', -> { "disable #{Breakpoint.first.id}" }, 'cont'

      debug_code(program) { assert_equal 22, state.line }
    end

    def test_disabling_breakpoints_with_full_syntax_sets_enabled_to_false
      enter 'b 21', 'b 22', -> { "disable breakpoints #{Breakpoint.first.id}" }

      debug_code(program) { assert_equal false, Breakpoint.first.enabled? }
    end

    def test_disabling_breakpoints_with_full_syntax_properly_ignores_them
      enter 'break 21', 'break 22',
            -> { "disable breakpoints #{Breakpoint.first.id}" }, 'cont'

      debug_code(program) { assert_equal 22, state.line }
    end

    def test_disabling_all_breakpoints_sets_all_enabled_flags_to_false
      enter 'break 21', 'break 22', 'disable breakpoints'

      debug_code(program) do
        assert_equal false, Breakpoint.first.enabled?
        assert_equal false, Breakpoint.last.enabled?
      end
    end

    def test_disabling_all_breakpoints_ignores_all_breakpoints
      enter 'break 21', 'break 22', 'disable breakpoints', 'cont'
      debug_code(program)

      assert_equal true, state.proceed # Obscure assert to check termination
    end

    def test_disabling_breakpoints_shows_an_error_in_syntax_is_incorrect
      enter 'disable'
      debug_code(program)

      check_error_includes '"disable" must be followed by "display", ' \
                           '"breakpoints" or breakpoint ids'
    end

    def test_disabling_breakpoints_shows_an_error_if_no_breakpoints_are_set
      enter 'disable 1'
      debug_code(program)

      check_error_includes 'No breakpoints have been set'
    end

    def test_disabling_breakpoints_shows_an_error_if_non_numeric_arg_is_provided
      enter 'break 5', 'disable foo'
      debug_code(program)

      check_error_includes \
        '"disable breakpoints" argument "foo" needs to be a number'
    end

    def test_enabling_breakpoints_with_short_syntax_sets_enabled_to_true
      enter 'b 21', 'b 22', 'disable breakpoints',
            -> { "enable #{Breakpoint.first.id}" }

      debug_code(program) { assert_equal true, Breakpoint.first.enabled? }
    end

    def test_enabling_breakpoints_with_short_syntax_stops_at_enabled_breakpoint
      enter 'break 21', 'break 22', 'disable breakpoints',
            -> { "enable #{Breakpoint.first.id}" }, 'cont'

      debug_code(program) { assert_equal 21, state.line }
    end

    def test_enabling_all_breakpoints_sets_all_enabled_flags_to_true
      enter 'break 21', 'break 22', 'disable breakpoints', 'enable breakpoints'

      debug_code(program) do
        assert_equal true, Breakpoint.first.enabled?
        assert_equal true, Breakpoint.last.enabled?
      end
    end

    def test_enabling_all_breakpoints_stops_at_first_breakpoint
      enter 'b 21', 'b 22', 'disable breakpoints', 'enable breakpoints', 'cont'

      debug_code(program) { assert_equal 21, state.line }
    end

    def test_enabling_all_breakpoints_stops_at_last_breakpoint
      enter 'break 21', 'break 22', 'disable breakpoints',
            'enable breakpoints', 'cont', 'cont'

      debug_code(program) { assert_equal 22, state.line }
    end

    def test_enabling_breakpoints_with_full_syntax_sets_enabled_to_false
      enter 'break 21', 'break 22', 'disable breakpoints',
            -> { "enable breakpoints #{Breakpoint.last.id}" }

      debug_code(program) { assert_equal false, Breakpoint.first.enabled? }
    end

    def test_enabling_breakpoints_with_full_syntax_stops_at_enabled_breakpoint
      enter 'break 21', 'break 22', 'disable breakpoints',
            -> { "enable breakpoints #{Breakpoint.last.id}" }, 'cont'

      debug_code(program) { assert_equal 22, state.line }
    end

    def test_enabling_breakpoints_shows_an_error_in_syntax_is_incorrect
      enter 'enable'
      debug_code(program)

      check_error_includes '"enable" must be followed by "display", ' \
                           '"breakpoints" or breakpoint ids'
    end
  end
end
