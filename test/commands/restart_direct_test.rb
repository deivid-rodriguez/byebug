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
        assert_restarts(
          "#{byebug_bin} #{example_path}",
          "restart",
          "Run program #{example_path} with no args"
        )
      end

      def test_restart_with_no_args__original_script_with_no_args__attached
        assert_restarts(
          example_path,
          "restart",
          "Run program #{example_path} with no args"
        )
      end

      def test_restart_with_no_args__standalone
        assert_restarts(
          "#{byebug_bin} #{example_path} 1",
          "restart",
          "Run program #{example_path} with args 1"
        )
      end

      def test_restart_with_args__standalone
        assert_restarts(
          "#{byebug_bin} #{example_path} 1",
          "restart 2",
          "Run program #{example_path} with args 2"
        )
      end

      def test_restart_with_no_args__attached
        assert_restarts(
          "#{example_path} 1",
          "restart",
          "Run program #{example_path} with args 1"
        )
      end

      def test_restart_with_args__attached
        assert_restarts(
          "#{example_path} 1",
          "restart 2",
          "Run program #{example_path} with args 2"
        )
      end
    end
  end
end
