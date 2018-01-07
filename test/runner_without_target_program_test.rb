# frozen_string_literal: true

require "test_helper"
require "byebug/version"

module Byebug
  #
  # Tests standalone byebug when flags that require no target program are used
  #
  class RunnerWithoutTargetProgramTest < TestCase
    def test_run_with_version_flag
      stdout = run_byebug("--version")

      assert_match(/#{Byebug::VERSION}/, stdout)
    end

    def test_run_with_help_flag
      stdout = run_byebug("--help")

      opts = [/-d/, /-I/, /-q/, /-s/, /-x/, /-m/, /-r/, /-R/, /-t/, /-v/, /-h/]

      opts.each { |regexp| assert_match(regexp, stdout) }
    end

    def test_run_with_remote_option_only_with_a_port_number
      stdout = run_byebug("--remote", "9999")

      assert_match(
        /Connecting to byebug server at localhost:9999\.\.\./,
        stdout
      )
    end

    def test_run_with_remote_option_with_host_and_port_specification
      stdout = run_byebug("--remote", "myhost:9999")

      assert_match(/Connecting to byebug server at myhost:9999\.\.\./, stdout)
    end

    def test_run_without_a_script_to_debug
      stdout = run_byebug

      assert_match_error("You must specify a program to debug", stdout)
    end

    def test_run_with_an_nonexistent_script
      stdout = run_byebug("non_existent_script.rb")

      assert_match_error("The script doesn't exist", stdout)
    end

    def test_run_with_an_invalid_script
      example_file.write("[1,2,")
      example_file.close

      stdout = run_byebug(example_path)

      assert_match_error("The script has incorrect syntax", stdout)
    end

    private

    def assert_match_error(message, output)
      assert_match(/\*\*\* #{message}/, output)
    end
  end
end
