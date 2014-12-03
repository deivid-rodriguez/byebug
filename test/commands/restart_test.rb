module Byebug
  #
  # Tests restarting functionality.
  #
  class RestartTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  byebug
        2:
        3:  ARGV.join(' ')
      EOC
    end

    def test_restarts_without_arguments_uses_original_arguments
      with_command_line(example_path, '1', '2') do
        RestartCommand.any_instance.expects(:exec).with("#{example_path} 1 2")

        enter 'restart 1 2'
        debug_code(program)
        check_output_includes "Re exec'ing:", "\t#{example_path} 1 2"
      end
    end

    def test_restarts_with_arguments_uses_passed_arguments
      with_command_line(example_path, '1', '2') do
        RestartCommand.any_instance.expects(:exec).with("#{example_path} 3 4")

        enter 'restart 3 4'
        debug_code(program)
        check_output_includes "Re exec'ing:", "\t#{example_path} 3 4"
      end
    end
  end
end
