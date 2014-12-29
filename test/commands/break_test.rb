module Byebug
  #
  # Tests breakpoint functionality.
  #
  class BreakTestCase < TestCase
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

    def test_setting_breakpoint_sets_correct_fields
      enter 'break 21'

      debug_code(program) do
        b = Breakpoint.first
        exp = [b.pos, b.source, b.expr, b.hit_count, b.hit_value, b.enabled?]
        act = [21, example_fullpath, nil, 0, 0, true]
        assert_equal act, exp
      end
    end

    def test_setting_breakpoint_using_shortcut_properly_adds_the_breakpoint
      enter 'break 21'

      debug_code(program) { assert_equal 1, Byebug.breakpoints.size }
    end

    def test_setting_breakpoint_to_nonexistent_line_does_not_create_breakpoint
      enter 'break 1000'

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    def test_setting_breakpoint_to_nonexistent_file_does_not_create_breakpoint
      enter 'break asf:324'

      debug_code(program) { assert_empty Byebug.breakpoints }
      check_error_includes 'No file named asf'
    end

    def test_setting_breakpoint_to_invalid_line_does_not_create_breakpoint
      enter 'break 9'

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    def test_stops_at_the_correct_place_when_a_breakpoint_is_set
      enter 'break 21', 'cont'

      debug_code(program) do
        assert_equal 21, state.line
        assert_equal example_path, state.file
      end
    end

    def test_setting_breakpoint_to_an_instance_method_stops_at_correct_place
      enter "break #{example_class}#b", 'cont'

      debug_code(program) do
        assert_equal 10, state.line
        assert_equal example_path, state.file
      end
    end

    def test_setting_breakpoint_to_a_class_method_stops_at_correct_place
      enter "break #{example_class}.a", 'cont'

      debug_code(program) do
        assert_equal 6, state.line
        assert_equal example_path, state.file
      end
    end

    def test_setting_breakpoint_to_nonexistent_class_does_not_create_breakpoint
      enter 'break B.a'

      debug_code(program)
      check_error_includes 'Unknown class B'
    end

    def test_setting_breakpoint_to_nonexistent_class_shows_error_message
      enter 'break B.a'

      debug_code(program)
      check_error_includes 'Unknown class B'
    end

    def test_setting_breakpoint_to_invalid_location_does_not_create_breakpoint
      enter 'break foo'

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    def test_breaking_w_byebug_keywork_stops_at_the_next_line
      debug_code(program) { assert_equal 19, state.line }
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

    def test_conditional_breakpoint_stops_if_condition_is_true
      enter 'break 21 if z == 5', 'break 22', 'cont'

      debug_code(program) { assert_equal 21, state.line }
    end

    def test_conditional_breakpoint_is_ignored_if_condition_is_false
      enter 'break 21 if z == 3', 'break 22', 'cont'

      debug_code(program) { assert_equal 22, state.line }
    end

    def test_setting_conditional_breakpoint_shows_error_if_no_breakpoint_id
      enter 'break if z == 3', 'break 22', 'cont'

      debug_code(program) { assert_equal 22, state.line }
      check_error_includes 'Invalid breakpoint id. Use "info breakpoint" to ' \
                           'find out the correct id'
    end

    def test_setting_conditional_breakpoint_using_wrong_expression_ignores_it
      enter 'break if z -=) 3', 'break 22', 'cont'

      debug_code(program) { assert_equal 22, state.line }
    end

    def test_shows_info_about_setting_breakpoints_when_using_just_break
      enter 'break', 'cont'
      debug_code(program)

      check_output_includes(/b\[reak\] file:line \[if expr\]/)
    end

    def test_setting_breakpoint_uses_new_source
      enter -> { cmd_after_replace(example_fullpath, 21, '', 'break 21') }

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    module FilenameTests
      def test_setting_breakpoint_prints_confirmation_message
        enter 'break 21'
        debug_code(program) { @id = Breakpoint.first.id }

        check_output_includes "Created breakpoint #{@id} at #{@filename}:21"
      end

      def test_setting_breakpoint_to_nonexistent_line_shows_an_error
        enter 'break 1000'
        debug_code(program)

        check_error_includes "There are only 23 lines in file #{@filename}"
      end

      def test_setting_breakpoint_to_invalid_line_shows_an_error
        enter 'break 9'
        debug_code(program)

        check_error_includes \
          "Line 9 is not a valid breakpoint in file #{@filename}"
      end
    end

    class BreakTestCaseBasename < BreakTestCase
      def setup
        super

        @filename = File.basename(example_fullpath)
        enter 'set basename'
      end

      include FilenameTests
    end

    class BreakTestCaseNobasename < BreakTestCase
      def setup
        super

        @filename = example_fullpath
        enter 'set nobasename'
      end

      include FilenameTests
    end
  end

  #
  # Tests entering byebug at the end of a method.
  #
  class BreakDeepTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test breakpoints
         4:    #
         5:    class #{example_class}
         6:      def a
         7:        byebug
         8:      end
         9:
        10:      new.a
        11:    end
        12:  end
      EOC
    end

    def test_breaking_w_byebug_keywork_stops_at_frame_end_when_last_instruction
      debug_code(program) { assert_equal 8, state.line }
    end
  end
end
