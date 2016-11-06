require 'test_helper'

module Byebug
  #
  # Tests adding conditions to breakpoints.
  #
  class ConditionTest < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    byebug
        3:
        4:    b = 5
        5:    c = b + 5
        6:    c + 3
        7:  end
      EOC
    end

    def test_setting_condition_assigns_expression_to_breakpoint
      enter 'break 5', -> { "condition #{Breakpoint.first.id} b == 5" }

      debug_code(program) { assert_equal 'b == 5', Breakpoint.first.expr }
    end

    def test_setting_condition_w_wrong_syntax_does_not_enable_breakpoint
      enter 'break 5',
            -> { "disable b #{Breakpoint.first.id}" },
            -> { "cond #{Breakpoint.first.id} b ==" }

      debug_code(program) { assert_equal false, Breakpoint.first.enabled? }
    end

    def test_setting_condition_w_wrong_syntax_shows_error
      enter 'break 5',
            -> { "disable #{Breakpoint.first.id}" },
            -> { "cond #{Breakpoint.first.id} b ==" }

      debug_code(program)
      check_error_includes \
        'Incorrect expression "b ==", breakpoint not changed'
    end

    def test_execution_stops_when_condition_is_true
      enter 'break 5', -> { "cond #{Breakpoint.first.id} b == 5" }, 'cont'

      debug_code(program) { assert_equal 5, frame.line }
    end

    def test_execution_does_not_stop_when_condition_is_false
      enter 'b 5', 'b 6', -> { "cond #{Breakpoint.first.id} b == 3" }, 'cont'

      debug_code(program) { assert_equal 6, frame.line }
    end

    def test_conditions_with_wrong_syntax_are_ignored
      enter 'b 5', 'b 6', -> { "cond #{Breakpoint.first.id} b ==" }, 'cont'

      debug_code(program) { assert_equal 5, frame.line }
    end

    def test_empty_condition_means_removing_any_conditions
      enter 'b 5 if b == 3', 'b 6', -> { "cond #{Breakpoint.first.id}" }, 'c'

      debug_code(program) do
        assert_nil Breakpoint.first.expr
        assert_equal 5, frame.line
      end
    end

    def test_shows_error_if_there_are_no_breakpoints
      enter 'cond 1 true'

      debug_code(program)
      check_error_includes 'No breakpoints have been set'
    end

    def test_shows_error_if_breakpoint_id_is_incorrect
      enter 'break 5', -> { "cond #{Breakpoint.last.id + 1} b == 3" }

      debug_code(program)
      check_error_includes \
        'Invalid breakpoint id. ' \
        'Use "info breakpoint" to find out the correct id'
    end
  end
end
