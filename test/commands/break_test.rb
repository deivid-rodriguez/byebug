module Byebug
  class BreakExample
    def self.a(num)
      4
    end

    def b
      3
    end
  end

  class BreakTestCase < TestCase
    def setup
      @example = -> do
        y = 3
        # A comment
        byebug
        z = 5
        BreakExample.new.b
        BreakExample.a(y+z)
      end

      super
    end

    def test_setting_breakpoint_sets_correct_fields
      enter 'break 19'

      debug_proc(@example) do
        assert_equal 19, Breakpoint.first.pos
        assert_equal __FILE__, Breakpoint.first.source
        assert_equal nil, Breakpoint.first.expr
        assert_equal 0, Breakpoint.first.hit_count
        assert_equal 0, Breakpoint.first.hit_value
        assert_equal true, Breakpoint.first.enabled?
      end
    end

    def test_setting_breakpoint_using_shortcut_properly_adds_the_breakpoint
      enter 'break 19'
      debug_proc(@example) { assert_equal 1, Byebug.breakpoints.size }
    end

    def test_setting_breakpoint_to_nonexistent_line_does_not_create_breakpoint
      enter 'break 1000'
      debug_proc(@example) { assert_empty Byebug.breakpoints }
    end

    def test_setting_breakpoint_to_nonexistent_file_does_not_create_breakpoint
      enter 'break asf:324'
      debug_proc(@example) { assert_empty Byebug.breakpoints }
      check_error_includes 'No file named asf'
    end

    def test_setting_breakpoint_to_invalid_line_does_not_create_breakpoint
      enter 'break 6'
      debug_proc(@example) { assert_empty Byebug.breakpoints }
    end

    def test_stops_at_the_correct_place_when_a_breakpoint_is_set
      enter 'break 19', 'cont'
      debug_proc(@example) do
        assert_equal 19, state.line
        assert_equal __FILE__, state.file
      end
    end

    def test_setting_breakpoint_to_an_instance_method_stops_at_correct_place
      enter 'break BreakExample#b', 'cont'

      debug_proc(@example) do
        assert_equal 7, state.line
        assert_equal __FILE__, state.file
      end
    end

    def test_setting_breakpoint_to_a_class_method_stops_at_correct_place
      enter 'break BreakExample.a', 'cont'

      debug_proc(@example) do
        assert_equal 3, state.line
        assert_equal __FILE__, state.file
      end
    end

    def test_setting_breakpoint_to_nonexistent_class_does_not_create_breakpoint
      enter 'break B.a'

      debug_proc(@example)
      check_error_includes 'Unknown class B'
    end

    def test_setting_breakpoint_to_nonexistent_class_shows_error_message
      enter 'break B.a'

      debug_proc(@example)
      check_error_includes 'Unknown class B'
    end

    def test_setting_breakpoint_to_invalid_location_does_not_create_breakpoint
      enter 'break foo'

      debug_proc(@example) { assert_empty Byebug.breakpoints }
    end

    def test_setting_breakpoint_to_invalid_location_shows_error_message
      enter 'break foo'

      debug_proc(@example)
      check_error_includes 'Invalid breakpoint location: foo'
    end

    def test_breaking_w_byebug_keywork_stops_at_the_next_line
      debug_proc(@example) { assert_equal 18, state.line }
    end

    class BreakDeepExample
      def a
        z = 2
        b(z)
      end

      def b(num)
        v2 = 5 if 1 == num ; [1,2,v2].map { |a| a.to_f }
        c
      end

      def c
        z = 4
        z += 5
        byebug
      end
    end

    def test_breaking_w_byebug_keywork_stops_at_frame_end_when_last_instruction
      @deep_example = lambda do
        ex = BreakDeepExample.new.a
        2.times do
          ex = ex ? ex : 1
        end
      end

      debug_proc(@deep_example) { assert_equal 132, state.line }
    end

    def test_disabling_breakpoints_with_short_syntax_sets_enabled_to_false
      enter 'break 19', 'break 20', -> { "disable #{Breakpoint.first.id}" }

      debug_proc(@example) { assert_equal false, Breakpoint.first.enabled? }
    end

    def test_disabling_breakpoints_with_short_syntax_properly_ignores_them
      enter 'b 19', 'b 20', -> { "disable #{Breakpoint.first.id}" } , 'cont'

      debug_proc(@example) { assert_equal 20, state.line }
    end

    def test_disabling_breakpoints_with_full_syntax_sets_enabled_to_false
      enter 'b 19', 'b 20', -> { "disable breakpoints #{Breakpoint.first.id}" }

      debug_proc(@example) { assert_equal false, Breakpoint.first.enabled? }
    end

    def test_disabling_breakpoints_with_full_syntax_properly_ignores_them
      enter 'break 19', 'break 20',
            -> { "disable breakpoints #{Breakpoint.first.id}" }, 'cont'

      debug_proc(@example) { assert_equal 20, state.line }
    end

    def test_disabling_all_breakpoints_sets_all_enabled_flags_to_false
      enter 'break 19', 'break 20', 'disable breakpoints'

      debug_proc(@example) do
         assert_equal false, Breakpoint.first.enabled?
         assert_equal false, Breakpoint.last.enabled?
      end
    end

    def test_disabling_all_breakpoints_ignores_all_breakpoints
      enter 'break 19', 'break 20', 'disable breakpoints', 'cont'

      debug_proc(@example)
      assert_equal true, state.proceed # Obscure assert to check termination
    end

    def test_disabling_breakpoints_shows_an_error_in_syntax_is_incorrect
      enter 'disable'

      debug_proc(@example)
      check_error_includes '"disable" must be followed by "display", ' \
                           '"breakpoints" or breakpoint ids'
    end

    def test_disabling_breakpoints_shows_an_error_if_no_breakpoints_are_set
      enter 'disable 1'

      debug_proc(@example)
      check_error_includes 'No breakpoints have been set'
    end

    def test_disabling_breakpoints_shows_an_error_if_non_numeric_arg_is_provided
      enter 'break 5', 'disable foo'

      debug_proc(@example)
      check_error_includes \
        '"disable breakpoints" argument "foo" needs to be a number'
    end

    def test_enabling_breakpoints_with_short_syntax_sets_enabled_to_true
      enter 'b 19', 'b 20', 'disable breakpoints',
            -> { "enable #{Breakpoint.first.id}" }

      debug_proc(@example) { assert_equal true, Breakpoint.first.enabled? }
    end

    def test_enabling_breakpoints_with_short_syntax_stops_at_enabled_breakpoint
      enter 'break 19', 'break 20', 'disable breakpoints',
            -> { "enable #{Breakpoint.first.id}" }, 'cont'

      debug_proc(@example) { assert_equal 19, state.line }
    end

    def test_enabling_all_breakpoints_sets_all_enabled_flags_to_true
      enter 'break 19', 'break 20', 'disable breakpoints', 'enable breakpoints'

      debug_proc(@example) do
         assert_equal true, Breakpoint.first.enabled?
         assert_equal true, Breakpoint.last.enabled?
      end
    end

    def test_enabling_all_breakpoints_stops_at_first_breakpoint
      enter 'b 19', 'b 20', 'disable breakpoints', 'enable breakpoints', 'cont'

      debug_proc(@example) { assert_equal 19, state.line }
    end

    def test_enabling_all_breakpoints_stops_at_last_breakpoint
      enter 'break 19', 'break 20', 'disable breakpoints',
            'enable breakpoints', 'cont', 'cont'

      debug_proc(@example) { assert_equal 20, state.line }
    end

    def test_enabling_breakpoints_with_full_syntax_sets_enabled_to_false
      enter 'break 19', 'break 20', 'disable breakpoints',
            -> { "enable breakpoints #{Breakpoint.last.id}" }

      debug_proc(@example) { assert_equal false, Breakpoint.first.enabled? }
    end

    def test_enabling_breakpoints_with_full_syntax_stops_at_enabled_breakpoint
      enter 'break 19', 'break 20', 'disable breakpoints',
            -> { "enable breakpoints #{Breakpoint.last.id}" }, 'cont'

      debug_proc(@example) { assert_equal 20, state.line }
    end

    def test_enabling_breakpoints_shows_an_error_in_syntax_is_incorrect
      enter 'enable'

      debug_proc(@example)
      check_error_includes '"enable" must be followed by "display", ' \
                           '"breakpoints" or breakpoint ids'
    end

    def test_conditional_breakpoint_stops_if_condition_is_true
      enter 'break 19 if z == 5', 'break 20', 'cont'
      debug_proc(@example) { assert_equal 19, state.line }
    end

    def test_conditional_breakpoint_is_ignored_if_condition_is_false
      enter 'break 19 if z == 3', 'break 20', 'cont'
      debug_proc(@example) { assert_equal 20, state.line }
    end

    def test_setting_conditional_breakpoint_shows_error_if_syntax_wrong
      enter 'break 19 ifa z == 3', 'break 20', 'cont'
      debug_proc(@example) { assert_equal 20, state.line }
      check_error_includes \
        'Expecting "if" in breakpoint condition, got: ifa z == 3'
    end

    def test_setting_conditional_breakpoint_shows_error_if_no_breakpoint_id
      enter 'break if z == 3', 'break 20', 'cont'
      debug_proc(@example) { assert_equal 20, state.line }
      check_error_includes 'Invalid breakpoint location: if z == 3'
    end

    def test_setting_conditional_breakpoint_using_wrong_expression_ignores_it
      enter 'break if z -=) 3', 'break 20', 'cont'
      debug_proc(@example) { assert_equal 20, state.line }
    end

    def test_shows_info_about_setting_breakpoints_when_using_just_break
      enter 'break', 'cont'
      debug_proc(@example)
      check_output_includes(/b\[reak\] file:line \[if expr\]/)
    end
  end

  module FilenameTests
    def test_setting_breakpoint_prints_confirmation_message
      enter 'break 19'
      debug_proc(@example) { @id = Breakpoint.first.id }
      check_output_includes "Created breakpoint #{@id} at #{@filename}:19"
    end

    def test_setting_breakpoint_to_nonexistent_line_shows_an_error
      enter 'break 1000'
      debug_proc(@example)
      n = %x{wc -l #{__FILE__}}.split.first.to_i
      check_error_includes "There are only #{n} lines in file #{@filename}"
    end

    def test_setting_breakpoint_to_invalid_line_shows_an_error
      enter 'break 6'
      debug_proc(@example)
      check_error_includes \
        "Line 6 is not a valid breakpoint in file #{@filename}"
    end
  end

  class BreakTestCaseBasename < BreakTestCase
    def setup
      @filename = File.basename(__FILE__)
      super
      enter 'set basename'
    end

    include FilenameTests
  end

  class BreakTestCaseNobasename < BreakTestCase
    def setup
      @filename = __FILE__
      super
      enter 'set nobasename'
    end

    include FilenameTests
  end

  def test_setting_breakpoint_with_autoreload_uses_new_source
    enter 'set autoreload', -> do
      change_line_in_file(__FILE__, 19, '')
      'break 19'
    end

    debug_proc(@example) { assert_empty Byebug.breakpoints }
    change_line_in_file(__FILE__,19, '        BreakExample.new.b')
  end

  def test_setting_breakpoint_with_noautoreload_uses_old_source
    enter 'set noautoreload', -> do
      change_line_in_file(__FILE__, 19, '')
      'break 19'
    end

    debug_proc(@example) { assert_equal 1, Byebug.breakpoints.size }
    change_line_in_file(__FILE__,19, '        BreakExample.new.b')
  end
end
