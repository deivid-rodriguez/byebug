# frozen_string_literal: true

require "test_helper"
require "byebug/runner"

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
      with_command_line("exe/byebug", example_path) do
        non_stop_runner.run

        assert_equal $PROGRAM_NAME, example_path
      end
    end

    def test_run_with_a_script_and_params_does_not_consume_script_params
      with_command_line("exe/byebug", "--", example_path, "-opt", "value") do
        non_stop_runner.run

        assert_equal ["-opt", "value"], $ARGV
      end
    end

    def test_run_with_ruby_is_ignored_and_script_passed_instead
      with_command_line("exe/byebug", "--", "ruby", example_path) do
        non_stop_runner.run

        assert_equal example_path, $PROGRAM_NAME
      end
    end

    def test_run_with_fullpath_ruby_is_ignored_and_script_passed_instead
      with_command_line("exe/byebug", "--", RbConfig.ruby, example_path) do
        non_stop_runner.run

        assert_equal example_path, $PROGRAM_NAME
      end
    end

    def test_run_with_post_mortem_mode_flag
      with_setting :post_mortem, false do
        with_command_line("exe/byebug", "-m", example_path) do
          non_stop_runner.run

          assert_equal true, Setting[:post_mortem]
        end
      end
    end

    def test_run_with_linetracing_flag
      with_setting :linetrace, false do
        with_command_line("exe/byebug", "-t", example_path) do
          non_stop_runner.run

          assert_equal true, Setting[:linetrace]
        end
      end
    end

    def test_run_with_no_quit_flag
      skip

      with_command_line("exe/byebug", "--no-quit", example_path) do
        non_stop_runner.run

        check_output_includes("(byebug:ctrl)")
      end
    end

    def test_run_with_require_flag
      with_command_line("exe/byebug", "-r", "abbrev", example_path) do
        non_stop_runner.run
      end

      hsh = { "can" => "can", "cat" => "cat" }
      assert_equal hsh, %w[can cat].abbrev
    end

    def test_run_with_a_single_include_flag
      with_command_line("exe/byebug", "-I", "dir1", example_path) do
        non_stop_runner.run
      end

      assert_includes $LOAD_PATH, "dir1"
    end

    def test_run_with_several_include_flags
      with_command_line("exe/byebug", "-I", "dir1:dir2", example_path) do
        non_stop_runner.run
      end

      assert_includes $LOAD_PATH, "dir1"
      assert_includes $LOAD_PATH, "dir2"
    end

    def test_run_with_debug_flag
      with_command_line("exe/byebug", "-d", example_path) do
        non_stop_runner.run
      end

      assert_equal $DEBUG, true
      $DEBUG = false
    end

    def test_run_stops_at_the_first_line_by_default
      enter "cont"
      with_command_line("exe/byebug", example_path) { stop_first_runner.run }

      check_output_includes "=> 1: sleep 0"
    end

    def test_run_with_no_stop_flag_does_not_stop_at_the_first_line
      non_stop_runner.interface = Context.interface

      with_command_line("exe/byebug --no-stop", example_path) do
        non_stop_runner.run
      end

      assert_empty non_stop_runner.interface.output
    end

    def test_run_with_stop_flag_stops_at_the_first_line
      enter "cont"

      with_command_line("exe/byebug --stop", example_path) do
        stop_first_runner.run
      end

      check_output_includes "=> 1: sleep 0"
    end

    private

    def non_stop_runner
      @non_stop_runner ||= Byebug::Runner.new(false)
    end

    def stop_first_runner
      @stop_first_runner ||= Byebug::Runner.new(true)
    end
  end
end
