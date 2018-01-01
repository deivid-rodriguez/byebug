# frozen_string_literal: true

require "test_helper"
require "rbconfig"
require "minitest/mock"

module Byebug
  #
  # Tests restarting functionality.
  #
  class RestartTest < TestCase
    def test_restart_with_no_args_original_script_with_no_args_standalone_mode
      with_mode(:standalone) do
        with_command_line(example_path) do
          assert_restarts(nil, "#{ruby_bin} #{byebug_bin} #{example_path}")
        end
      end
    end

    def test_restart_with_no_args_original_script_with_no_args_attached_mode
      with_mode(:attached) do
        with_command_line(example_path) do
          assert_restarts(nil, "#{ruby_bin} #{example_path}")
        end
      end
    end

    def test_restart_with_no_args_original_script_through_ruby_attached_mode
      with_mode(:attached) do
        with_command_line("ruby", example_path) do
          assert_restarts(nil, "ruby #{example_path}")
        end
      end
    end

    def test_restart_with_no_args_in_standalone_mode
      with_mode(:standalone) do
        with_command_line(example_path, "1") do
          assert_restarts(nil, "#{ruby_bin} #{byebug_bin} #{example_path} 1")
        end
      end
    end

    def test_restart_with_args_in_standalone_mode
      with_mode(:standalone) do
        with_command_line(example_path, "1") do
          assert_restarts("2", "#{ruby_bin} #{byebug_bin} #{example_path} 2")
        end
      end
    end

    def test_restart_with_no_args_in_attached_mode
      with_mode(:attached) do
        with_command_line(example_path, "1") do
          assert_restarts(nil, "#{ruby_bin} #{example_path} 1")
        end
      end
    end

    def test_restart_with_args_in_attached_mode
      with_mode(:attached) do
        with_command_line(example_path, "1") do
          assert_restarts(2, "#{ruby_bin} #{example_path} 2")
        end
      end
    end

    private

    def assert_restarts(arg, expected_cmd_line)
      assert_calls(Kernel, :exec, expected_cmd_line) do
        enter ["restart", arg].compact.join(" ")
        debug_code(minimal_program)

        check_output_includes "Re exec'ing:"
      end
    end

    def ruby_bin
      RbConfig.ruby
    end

    def byebug_bin
      Context.bin_file
    end
  end
end
