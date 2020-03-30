# frozen_string_literal: true

require_relative "test_helper"
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
      stdout = run_byebug(
        example_path,
        input: 'puts "Program: #{$PROGRAM_NAME}"'
      )

      assert_match(/Program: #{example_path}/, stdout)
    end

    def test_run_with_a_script_and_params_does_not_consume_script_params
      stdout = run_byebug(
        "--", example_path, "-opt", "value",
        input: 'puts "Args: #{$ARGV.join(\', \')}"'
      )

      assert_match(/Args: -opt, value/, stdout)
    end

    def test_run_with_ruby_is_ignored_and_script_passed_instead
      stdout = run_byebug(
        "--", "ruby", example_path,
        input: 'puts "Program: #{$0}"'
      )

      assert_match(/Program: #{example_path}/, stdout)
    end

    def test_run_with_fullpath_ruby_is_ignored_and_script_passed_instead
      stdout = run_byebug(
        "--", RbConfig.ruby, example_path,
        input: 'puts "Program: #{$0}"'
      )

      assert_match(/Program: #{example_path}/, stdout)
    end

    def test_run_with_post_mortem_mode_flag
      stdout = run_byebug(
        "-m", example_path,
        input: "show post_mortem\nset post_mortem off"
      )

      assert_match(/post_mortem is on/, stdout)
    end

    def test_run_with_linetracing_flag
      stdout = run_byebug(
        "-t", example_path,
        input: "show linetrace\nset linetrace off"
      )

      assert_match(/linetrace is on/, stdout)
    end

    def test_run_with_no_quit_flag
      skip

      stdout = run_byebug(
        "--no-quit", example_path,
        input: "cont\nquit!"
      )

      assert_match(/\(byebug:ctrl\)/, stdout)
    end

    def test_run_with_require_flag
      stdout = run_byebug(
        "-r", example_path, example_path,
        input: \
          "puts \"Example path loaded? \#{$LOADED_FEATURES.include?('#{example_path}')}\""
      )

      assert_match(/Example path loaded\? true/, stdout)
    end

    def test_run_with_a_single_include_flag
      stdout = run_byebug(
        "-I", "dir1", example_path,
        input: 'puts "dir1 in LOAD_PATH? #{$LOAD_PATH.include?(\'dir1\')}"'
      )

      assert_match(/dir1 in LOAD_PATH\? true/, stdout)
    end

    def test_run_with_several_include_flags
      stdout = run_byebug(
        "-I", "d1:d2", example_path,
        input: \
          'puts "d1 and d2 in LOAD_PATH? #{(%w(d1 d2) - $LOAD_PATH).empty?}"'
      )

      assert_match(/d1 and d2 in LOAD_PATH\? true/, stdout)
    end

    def test_run_with_debug_flag
      stdout = run_byebug(
        "-d", example_path,
        input: 'puts "Debug flag is #{$DEBUG}"'
      )

      assert_match(/Debug flag is true/, stdout)
    end

    def test_run_and_press_tab_doesnt_make_byebug_crash
      stdout = run_byebug(
        example_path,
        input: "\tputs 'Reached here'"
      )

      assert_match(/Reached here/, stdout)
    end

    def test_run_stops_at_the_first_line_by_default
      stdout = run_byebug(example_path)

      assert_match(/=> 1: sleep 0/, stdout)
    end

    def test_run_with_no_stop_flag_does_not_stop_at_the_first_line
      stdout = run_byebug("--no-stop", example_path)

      refute_match(/=> 1: sleep 0/, stdout)
    end

    def test_run_with_stop_flag_stops_at_the_first_line
      stdout = run_byebug("--stop", example_path)

      assert_match(/=> 1: sleep 0/, stdout)
    end
  end
end
