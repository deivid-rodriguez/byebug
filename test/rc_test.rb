# frozen_string_literal: true

require_relative "test_helper"
require "byebug/runner"

module Byebug
  class RcTest < TestCase
    def setup
      super

      example_file.write("sleep 0")
      example_file.close
    end

    def test_run_with_no_rc_option
      with_command_line("exe/byebug", "--no-rc", example_path) do
        refute_calls(Byebug, :run_init_script) { non_stop_runner.run }
      end
    end

    def test_rc_file_commands_are_properly_run_by_default
      rc_positive_test(nil)
    end

    def test_rc_file_commands_are_properly_run_by_explicit_option
      rc_positive_test("--rc")
    end

    def test_rc_file_commands_are_properly_run_when_home_folder_not_known
      with_env("HOME", nil) { rc_positive_test(nil) }
    end

    def test_rc_file_with_invalid_commands
      with_init_file("seta callstyle long") do
        with_command_line("exe/byebug", "--rc", example_path) do
          assert_output(nil, /Unknown command 'seta callstyle long'/) do
            non_stop_runner.run
          end
        end
      end
    end

    private

    def rc_positive_test(flag)
      args = [flag, example_path].compact

      with_setting :callstyle, "short" do
        with_init_file("set callstyle long") do
          with_command_line("exe/byebug", *args) do
            non_stop_runner.run

            assert_equal "long", Setting[:callstyle]
          end
        end
      end
    end

    def non_stop_runner
      @non_stop_runner ||= Byebug::Runner.new(false)
    end
  end
end
