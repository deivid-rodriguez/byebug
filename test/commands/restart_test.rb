require 'test_helper'

module Byebug
  #
  # Tests restarting functionality.
  #
  class RestartTest < TestCase
    def test_restart_without_arguments_uses_original_arguments
      with_command_line(example_path, '1') do
        assert_calls(Kernel, :exec, "#{example_path} 1") do
          enter 'restart'
          debug_code(minimal_program)

          check_output_includes "Re exec'ing:"
        end
      end
    end

    def test_restart_with_arguments_uses_passed_arguments
      with_command_line(example_path, '1') do
        assert_calls(Kernel, :exec, "#{example_path} 2") do
          enter 'restart 2'
          debug_code(minimal_program)

          check_output_includes "Re exec'ing:"
        end
      end
    end
  end
end
