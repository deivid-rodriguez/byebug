module Byebug
  #
  # Tests gloabal variable and line tracing functionality.
  #
  # TODO: split into 2 different tests
  #
  class TraceTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    initial = $VERBOSE
        3:    byebug
        4:    $VERBOSE = false
        5:    initial &&= true
        6:    $VERBOSE = false
        7:    $VERBOSE ||= false
        8:    $VERBOSE = initial
        9:  end
      EOC
    end

    def test_linetrace_setting_enables_tracing_program_execution
      enter 'set linetrace', 'cont 7', 'set nolinetrace'
      debug_code(program)
      check_output_includes 'linetrace is on',
                            "Tracing: #{example_path}:5   initial &&= true",
                            "Tracing: #{example_path}:6   $VERBOSE = false"
    end

    def test_basename_setting_affects_tracing_output
      enter 'set basename', 'set linetrace on', 'cont 6', 'set nolinetrace'
      debug_code(program)
      check_output_includes \
        "Tracing: #{File.basename(example_path)}:5   initial &&= true"
    end

    def test_disabling_linetrace_setting_stops_tracing
      enter 'set linetrace', 'next', 'set nolinetrace'
      debug_code(program)
      check_output_includes "Tracing: #{example_path}:5   initial &&= true"
      check_output_doesnt_include \
        "Tracing: #{example_path}:6   $VERBOSE = false"
    end

    def test_tracevar_tracks_global_variables
      enter 'tracevar $VERBOSE', 'cont 7', 'untracevar $VERBOSE'
      debug_code(program)
      check_output_includes \
        "traced global variable '$VERBOSE' has value 'false'",
        "traced global variable '$VERBOSE' has value 'false'"
    end

    def test_tracevar_stop_makes_program_stop_when_global_var_changes
      enter 'tracevar $VERBOSE stop', 'cont 7', 'untracevar $VERBOSE'
      debug_code(program) { assert_equal 5, state.line }
    end

    def test_tracevar_nostop_does_not_stop_when_global_var_changes
      enter 'tracevar $VERBOSE nostop', 'cont 7', 'untracevar $VERBOSE'
      debug_code(program) { assert_equal 7, state.line }
    end

    def test_tracevar_shows_an_error_message_if_no_global_variable_is_specified
      enter 'tracevar'
      debug_code(program)
      check_error_includes('tracevar needs a global variable name')
    end

    def test_tracevar_shows_an_error_message_if_there_is_no_such_global_var
      enter 'tracevar $FOO'
      debug_code(program)
      check_error_includes "'$FOO' is not a global variable."
    end
  end
end
