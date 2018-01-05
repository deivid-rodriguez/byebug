# frozen_string_literal: true

require "test_helper"
require "byebug/version"

module Byebug
  #
  # Tests standalone byebug when debugging a target program
  #
  class RunnerAgainstValidProgramTest < TestCase
    def setup
      super

      example_file.write("sleep 0")
      example_file.close
    end

    def test_run_with_a_script_to_debug
      stdout = run_program(
        [*binstub, example_path],
        'puts "Program: #{$PROGRAM_NAME}"'
      )

      assert_match(/Program: #{example_path}/, stdout)
    end

    def test_run_with_a_script_and_params_does_not_consume_script_params
      stdout = run_program(
        [*binstub, "--", example_path, "-opt", "value"],
        'puts "Args: #{$ARGV.join(\', \')}"'
      )

      assert_match(/Args: -opt, value/, stdout)
    end

    def test_run_with_ruby_script_ruby_is_ignored_and_script_passed_instead
      stdout = run_program(
        [*binstub, "--", RbConfig.ruby, example_path],
        'puts "Program: #{$0}"'
      )

      assert_match(/Program: #{example_path}/, stdout)
    end

    def test_run_with_post_mortem_mode_flag
      stdout = run_program(
        [*binstub, "-m", example_path],
        "show post_mortem"
      )

      assert_match(/post_mortem is on/, stdout)
    end

    def test_run_with_linetracing_flag
      stdout = run_program(
        [*binstub, "-t", example_path],
        "show linetrace"
      )

      assert_match(/linetrace is on/, stdout)
    end

    def test_run_with_no_quit_flag
      skip

      stdout = run_program(
        [*binstub, "--no-quit", example_path],
        "quit!"
      )

      assert_match(/\(byebug:ctrl\)/, stdout)
    end

    def test_run_with_require_flag
      stdout = run_program(
        [*binstub, "-r", "abbrev", example_path],
        'puts "Abbrev loaded? #{$LOADED_FEATURES.last.include?(\'abbrev\')}"'
      )

      assert_match(/Abbrev loaded\? true/, stdout)
    end

    def test_run_with_a_single_include_flag
      stdout = run_program(
        [*binstub, "-I", "dir1", example_path],
        'puts "dir1 in LOAD_PATH? #{$LOAD_PATH.include?(\'dir1\')}"'
      )

      assert_match(/dir1 in LOAD_PATH\? true/, stdout)
    end

    def test_run_with_several_include_flags
      stdout = run_program(
        [*binstub, "-I", "d1:d2", example_path],
        'puts "d1 and d2 in LOAD_PATH? #{(%w(d1 d2) - $LOAD_PATH).empty?}"'
      )

      assert_match(/d1 and d2 in LOAD_PATH\? true/, stdout)
    end

    def test_run_with_debug_flag
      stdout = run_program(
        [*binstub, "-d", example_path],
        'puts "Debug flag is #{$DEBUG}"'
      )

      assert_match(/Debug flag is true/, stdout)
    end

    def test_run_stops_at_the_first_line_by_default
      stdout = run_program([*binstub, example_path])

      assert_match(/=> 1: sleep 0/, stdout)
    end

    def test_run_with_no_stop_flag_does_not_stop_at_the_first_line
      stdout = run_program([*binstub, "--no-stop", example_path])

      refute_match(/=> 1: sleep 0/, stdout)
    end

    def test_run_with_stop_flag_stops_at_the_first_line
      stdout = run_program([*binstub, "--stop", example_path])

      assert_match(/=> 1: sleep 0/, stdout)
    end
  end
end
