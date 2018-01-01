# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests gloabal variable tracing functionality.
  #
  class TracevarTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test global variable tracing
         4:    #
         5:    class #{example_class}
         6:      def with_verbose(value)
         7:        previous = $VERBOSE
         8:        $VERBOSE = value
         9:        yield
        10:      ensure
        11:        $VERBOSE = previous
        12:      end
        13:    end
        14:
        15:    #{example_class}.new.with_verbose(true) do
        16:      byebug
        17:      $VERBOSE = false
        18:      $VERBOSE ||= true
        19:      $VERBOSE &&= false
        20:    end
        21:  end
      RUBY
    end

    def test_tracevar_tracks_global_variables
      enter "tracevar $VERBOSE", "cont 19", "untracevar $VERBOSE"
      debug_code(program)

      check_output_includes \
        "traced global variable '$VERBOSE' has value 'false'",
        "traced global variable '$VERBOSE' has value 'true'"
    end

    def test_tracevar_stop_makes_program_stop_when_global_var_changes
      enter "tracevar $VERBOSE stop", "cont 19", "untracevar $VERBOSE"

      debug_code(program) { assert_equal 18, frame.line }
    end

    def test_tracevar_nostop_does_not_stop_when_global_var_changes
      enter "tracevar $VERBOSE nostop", "cont 19", "untracevar $VERBOSE"

      debug_code(program) { assert_equal 19, frame.line }
    end

    def test_tracevar_shows_an_error_message_if_no_global_variable_is_specified
      enter "tracevar"
      debug_code(program)

      check_error_includes("tracevar needs a global variable name")
    end

    def test_tracevar_shows_an_error_message_if_there_is_no_such_global_var
      enter "tracevar $FOO"
      debug_code(program)

      check_error_includes "'$FOO' is not a global variable."
    end
  end
end
