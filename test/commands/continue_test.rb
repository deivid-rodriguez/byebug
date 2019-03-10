# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests for continue command
  #
  class ContinueTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test continue command.
         4:    #
         5:    class #{example_class}
         6:      def add_four(num)
         7:        num + 4
         8:      end
         9:    end
        10:
        11:    byebug
        12:
        13:    b = 5
        14:    c = b + 5
        15:    #{example_class}.new.add_four(c)
        16:    eval("c")
        17:  end
      RUBY
    end

    def test_continues_until_the_end_if_no_line_specified_and_no_breakpoints
      enter "continue"

      debug_code(program) { assert_program_finished }
    end

    def test_continues_until_the_end_if_used_with_bang
      with_mode(:attached) do
        enter "break 14", "continue!"

        debug_code(program) { assert_program_finished }
      end
    end

    def test_continues_until_the_end_if_used_with_unconditionally
      with_mode(:attached) do
        enter "break 14", "continue unconditionally"

        debug_code(program) { assert_program_finished }
      end
    end

    def test_stops_byebug_after_continue
      enter "continue"

      debug_code(program) { assert_equal false, Byebug.started? }
    end

    def test_continues_up_to_breakpoint_if_no_line_specified
      enter "break 14", "continue"

      debug_code(program) { assert_equal 14, frame.line }
    end

    def test_works_in_abbreviated_mode_too
      enter "break 14", "cont"

      debug_code(program) { assert_equal 14, frame.line }
    end

    def test_continues_up_to_the_specified_line
      enter "cont 14"

      debug_code(program) { assert_equal 14, frame.line }
    end

    def test_ignores_the_command_if_specified_line_is_not_valid
      enter "cont 100"

      debug_code(program) { assert_equal 13, frame.line }
    end

    def test_shows_error_if_specified_line_is_not_valid
      enter "cont 100"
      debug_code(program)

      check_error_includes "Line 100 is not a valid stopping point in file"
    end

    def test_tracing_after_set_linetrace_and_continue
      with_setting :linetrace, false do
        enter "set linetrace", "cont"
        debug_code(program)

        check_output_includes "Tracing: #{example_path}:14   c = b + 5"
      end
    end

    def test_linetrace_does_not_show_a_line_in_eval_context
      with_setting :linetrace, true do
        enter "cont"
        debug_code(program)

        check_output_includes "Tracing: (eval):1"
      end
    end
  end

  class ContinueUnconditionallyWithByebugCallsTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    byebug
         3:
         4:    b = 5
         5:
         6:    byebug
         7:
         8:    c = b + 5
         9:
        10:    d = c + 5
        11:  end
      RUBY
    end

    def test_continues_until_the_end_ignoring_byebug_calls_if_used_with_bang
      with_mode(:attached) do
        enter "continue!"

        debug_code(program) { assert_program_finished }
      end
    end

    def test_continues_until_the_end_ignoring_byebug_calls_if_used_with_unconditionally
      with_mode(:attached) do
        enter "continue unconditionally"

        debug_code(program) { assert_program_finished }
      end
    end
  end
end
