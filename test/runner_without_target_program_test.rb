# frozen_string_literal: true

require "test_helper"
require "byebug/runner"

module Byebug
  #
  # Tests standalone byebug when flags that require no target program are used
  #
  class RunnerWithoutTargetProgramTest < TestCase
    def setup
      super

      runner.interface = Context.interface
    end

    def test_run_with_version_flag
      with_command_line("bin/byebug", "--version") { runner.run }

      check_output_includes(/#{Byebug::VERSION}/)
    end

    def test_run_with_help_flag
      with_command_line("bin/byebug", "--help") { runner.run }

      check_output_includes(
        /-d/, /-I/, /-q/, /-s/, /-x/, /-m/, /-r/, /-R/, /-t/, /-v/, /-h/
      )
    end

    def test_run_with_remote_option_only_with_a_port_number
      with_command_line("bin/byebug", "--remote", "9999") do
        assert_calls(Byebug, :start_client, "localhost 9999") { runner.run }
      end
    end

    def test_run_with_remote_option_with_host_and_port_specification
      with_command_line("bin/byebug", "--remote", "myhost:9999") do
        assert_calls(Byebug, :start_client, "myhost 9999") { runner.run }
      end
    end

    def test_run_without_a_script_to_debug
      with_command_line("bin/byebug") do
        runner.run

        check_error_includes "You must specify a program to debug"
      end
    end

    def test_run_with_an_nonexistent_script
      with_command_line("bin/byebug", "non_existent_script.rb") do
        runner.run

        check_error_includes "The script doesn't exist"
      end
    end

    def test_run_with_an_invalid_script
      example_file.write("[1,2,")
      example_file.close

      with_command_line("bin/byebug", example_path) do
        runner.run

        check_error_includes "The script has incorrect syntax"
      end
    end

    private

    def runner
      @runner ||= Byebug::Runner.new(false)
    end
  end
end
