module Byebug
  class ConditionTestCase < TestCase
    def setup
      @example = -> do
        byebug
        b = 5
        c = b + 5
        c = Object.new
      end

      super
    end

    def test_setting_condition_w_short_syntax_assigns_expression_to_breakpoint
      enter 'break 7', -> { "cond #{Breakpoint.first.id} b == 5" }

      debug_proc(@example) { assert_equal 'b == 5', Breakpoint.first.expr }
    end

    def test_setting_condition_w_full_syntax_assigns_expression_to_breakpoint
      enter 'break 7', -> { "condition #{Breakpoint.first.id} b == 5" }

      debug_proc(@example) { assert_equal 'b == 5', Breakpoint.first.expr }
    end

    def test_setting_condition_w_wrong_syntax_does_not_enable_breakpoint
      enter 'break 7', -> { "disable #{Breakpoint.first.id}" },
                       -> { "cond #{Breakpoint.first.id} b ==" }

      debug_proc(@example) { assert_equal false, Breakpoint.first.enabled? }
    end

    def test_setting_condition_w_wrong_syntax_shows_error
      enter 'break 7', -> { "disable #{Breakpoint.first.id}" },
                       -> { "cond #{Breakpoint.first.id} b ==" }

      debug_proc(@example)
      check_error_includes \
        'Incorrect expression "b ==", breakpoint not changed'
    end

    def test_execution_stops_when_condition_is_true
      enter 'break 7', -> { "cond #{Breakpoint.first.id} b == 5" }, 'cont'

      debug_proc(@example) { assert_equal 7, state.line }
    end

    def test_execution_does_not_stop_when_condition_is_false
      enter 'b 7', 'b 8', -> { "cond #{Breakpoint.first.id} b == 3" }, 'cont'

      debug_proc(@example) { assert_equal 8, state.line }
    end

    def test_conditions_with_wrong_syntax_are_ignored
      enter 'b 7', 'b 8', -> { "cond #{Breakpoint.first.id} b ==" }, 'cont'

      debug_proc(@example) { assert_equal 7, state.line }
    end

    def test_empty_condition_means_removing_any_conditions
      enter 'b 7 if b == 3', 'b 8', -> { "cond #{Breakpoint.first.id}" }, 'c'

      debug_proc(@example) do
        assert_nil Breakpoint.first.expr
        assert_equal 7, state.line
      end
    end

    def test_shows_error_if_there_are_no_breakpoints
      enter 'cond 1 true'

      debug_proc(@example)
      check_error_includes 'No breakpoints have been set'
    end

    def test_shows_error_if_breakpoint_id_is_incorrect
      enter 'break 7', 'cond 2 b == 3'

      debug_proc(@example)
      check_error_includes \
        'Invalid breakpoint id. ' \
        'Use "info breakpoint" to find out the correct id'
    end
  end
end
