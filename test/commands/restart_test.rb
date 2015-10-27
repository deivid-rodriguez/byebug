require 'mocha/mini_test'
require 'test_helper'

module Byebug
  #
  # Tests restarting functionality.
  #
  class RestartTest < TestCase
    def test_restart_without_arguments_uses_original_arguments
      with_command_line(example_path, '1') do
        RestartCommand.any_instance.expects(:exec).with(example_path, '1')

        enter 'restart'
        debug_code(minimal_program)
        check_output_includes "Re exec'ing:", "#{example_path} 1"
      end
    end

    def test_restart_with_arguments_uses_passed_arguments
      with_command_line(example_path, '1') do
        RestartCommand.any_instance.expects(:exec).with(example_path, '2')

        enter 'restart 2'
        debug_code(minimal_program)
        check_output_includes "Re exec'ing:", "#{example_path} 2"
      end
    end
  end
end
