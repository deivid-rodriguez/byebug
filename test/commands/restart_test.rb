require 'test_helper'

module Byebug
  #
  # Tests restarting functionality.
  #
  class RestartTest < TestCase
    def test_restart_without_arguments_in_standalone_mode
      with_mode(:standalone) do
        with_command_line(example_path, '1') do
          assert_restarts(nil, "#{Context.bin_file} #{example_path} 1")
        end
      end
    end

    def test_restart_with_arguments_in_standalone_mode
      with_mode(:standalone) do
        with_command_line(example_path, '1') do
          assert_restarts('2', "#{Context.bin_file} #{example_path} 2")
        end
      end
    end

    def test_restart_without_arguments_in_attached_mode
      with_mode(:attached) do
        with_command_line(example_path, '1') do
          assert_restarts(nil, "#{example_path} 1")
        end
      end
    end

    def test_restart_with_arguments_in_attached_mode
      with_mode(:attached) do
        with_command_line(example_path, '1') do
          assert_restarts(2, "#{example_path} 2")
        end
      end
    end

    private

    def assert_restarts(arg, expected_cmd_line)
      assert_calls(Kernel, :exec, expected_cmd_line) do
        enter ['restart', arg].compact.join(' ')
        debug_code(minimal_program)

        check_output_includes "Re exec'ing:"
      end
    end
  end
end
