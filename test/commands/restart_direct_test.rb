# frozen_string_literal: true

require "test_helper"
require "rbconfig"
require "byebug/helpers/string"
require "support/restart"

module Byebug
  unless Gem.win_platform?
    #
    # Tests restarting functionality when program was run directly.
    #
    class RestartDirectTest < TestCase
      include Helpers::StringHelper
      include RestartTestHelpers

      def test_restart_with_no_args__original_script_with_no_args__standalone
        stdout = run_program(
          { "MINITEST_TEST" => __method__.to_s },
          [byebug_bin, example_path],
          "restart"
        )

        assert_match(/Run program #{example_path} with no args/, stdout)
      end

      def test_restart_with_no_args__original_script_with_no_args__attached
        stdout = run_program(
          { "MINITEST_TEST" => __method__.to_s },
          [example_path],
          "restart"
        )

        assert_match(/Run program #{example_path} with no args/, stdout)
      end

      def test_restart_with_no_args__standalone
        stdout = run_program(
          { "MINITEST_TEST" => __method__.to_s },
          [byebug_bin, example_path, "1"],
          "restart"
        )

        assert_match(/Run program #{example_path} with args 1/, stdout)
      end

      def test_restart_with_args__standalone
        stdout = run_program(
          { "MINITEST_TEST" => __method__.to_s },
          [byebug_bin, example_path, "1"],
          "restart 2"
        )

        assert_match(/Run program #{example_path} with args 2/, stdout)
      end

      def test_restart_with_no_args__attached
        stdout = run_program(
          { "MINITEST_TEST" => __method__.to_s },
          [example_path, "1"],
          "restart"
        )

        assert_match(/Run program #{example_path} with args 1/, stdout)
      end

      def test_restart_with_args__attached
        stdout = run_program(
          { "MINITEST_TEST" => __method__.to_s },
          [example_path, "1"],
          "restart 2"
        )

        assert_match(/Run program #{example_path} with args 2/, stdout)
      end
    end
  end
end