module Byebug
  class TraceTestCase < TestCase
    def setup
      @example = lambda do
        initial = $VERBOSE
        byebug
        $VERBOSE = false
        initial &&= true
        $VERBOSE = false
        $VERBOSE ||= false
        $VERBOSE = initial
      end

      super
    end

    def test_linetrace_setting_enables_tracing_program_execution
      enter 'set linetrace', 'cont 10', 'set nolinetrace'
      debug_proc(@example)
      check_output_includes 'linetrace is on',
                            "Tracing: #{__FILE__}:8         initial &&= true",
                            "Tracing: #{__FILE__}:9         $VERBOSE = false"
    end

    def test_basename_setting_affects_tracing_output
      enter 'set basename', 'set linetrace on', 'cont 9', 'set nolinetrace'
      debug_proc(@example)
      check_output_includes \
        "Tracing: #{File.basename(__FILE__)}:8         initial &&= true"
    end

    def test_disabling_linetrace_setting_stops_tracing
      enter 'set linetrace', 'next', 'set nolinetrace'
      debug_proc(@example)
      check_output_includes "Tracing: #{__FILE__}:8         initial &&= true"
      check_output_doesnt_include "Tracing: #{__FILE__}:9  $VERBOSE = false"
    end

    def test_tracevar_tracks_global_variables
      enter 'tracevar $VERBOSE', 'cont 10', 'untracevar $VERBOSE'
      debug_proc(@example)
      check_output_includes \
        "traced global variable '$VERBOSE' has value 'false'",
        "traced global variable '$VERBOSE' has value 'false'"
    end

    def test_tracevar_stop_makes_program_stop_when_global_var_changes
      enter 'tracevar $VERBOSE stop', 'cont 10', 'untracevar $VERBOSE'
      debug_proc(@example) { assert_equal 8, state.line }
    end

    def test_tracevar_nostop_does_not_stop_when_global_var_changes
      enter 'tracevar $VERBOSE nostop', 'cont 10', 'untracevar $VERBOSE'
      debug_proc(@example) { assert_equal 10, state.line }
    end

    def test_tracevar_shows_an_error_message_if_no_global_variable_is_specified
      enter 'tracevar'
      debug_proc(@example)
      check_error_includes('tracevar needs a global variable name')
    end

    def test_tracevar_shows_an_error_message_if_there_is_no_such_global_var
      enter 'tracevar $FOO'
      debug_proc(@example)
      check_error_includes "'$FOO' is not a global variable."
    end

    def test_tracevar_shows_an_error_message_if_subcommand_is_invalid
      enter 'tracevar $VERBOSE foo'
      debug_proc(@example)
      check_error_includes "expecting 'stop' or 'nostop'; got 'foo'"
    end
  end
end
