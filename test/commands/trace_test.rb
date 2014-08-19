module Byebug
  class TraceTestCase < TestCase
    def setup
      @example = -> do
        $bla = 5
        byebug
        $bla = 7
        $bla = 8
        $bla = 9
        $bla = 10
        $bla = (0 == (10 % $bla))
      end
      untrace_var(:$bla) if defined?($bla)

      super
    end

    def test_linetrace_setting_enables_tracing_program_execution
      enter 'set linetrace', 'cont 11', 'set nolinetrace'
      debug_proc(@example)
      check_output_includes 'linetrace is on',
        "Tracing: #{__FILE__}:8         $bla = 8",
        "Tracing: #{__FILE__}:9         $bla = 9",
        "Tracing: #{__FILE__}:10         $bla = 10",
        "Tracing: #{__FILE__}:11         $bla = (0 == (10 % $bla))"
    end

    def test_basename_setting_affects_tracing_output
      enter 'set basename', 'set linetrace on', 'cont 10', 'set nolinetrace'
      debug_proc(@example)
      check_output_includes \
        "Tracing: #{File.basename(__FILE__)}:10         $bla = 10"
    end

    def test_disabling_linetrace_setting_stops_tracing
      enter 'set linetrace', 'next', 'set nolinetrace'
      debug_proc(@example)
      check_output_includes "Tracing: #{__FILE__}:8         $bla = 8"
      check_output_doesnt_include "Tracing: #{__FILE__}:9         $bla = 9"
    end

    def test_tracevar_tracks_global_variables
      enter 'tracevar bla'
      debug_proc(@example)
      check_output_includes "traced global variable 'bla' has value '7'",
                            "traced global variable 'bla' has value '10'"
    end

    def test_tracevar_stop_makes_program_stop_when_global_var_changes
      enter 'tracevar bla stop', 'break 10', 'cont'
      debug_proc(@example) { assert_equal 8, state.line }
    end

    def test_tracevar_nostop_does_not_stop_when_global_var_changes
      enter 'tracevar bla nostop', 'break 10', 'cont'
      debug_proc(@example) { assert_equal 10, state.line }
    end

    def test_tracevar_shows_an_error_message_if_there_is_no_such_global_var
      enter 'tracevar foo'
      debug_proc(@example)
      check_error_includes "'foo' is not a global variable."
    end

    def test_tracevar_shows_an_error_message_if_subcommand_is_invalid
      enter 'tracevar bla foo'
      debug_proc(@example)
      check_error_includes 'expecting "stop" or "nostop"; got "foo"'
    end
  end
end
