# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # A subclass of Interface to test the base class functionality
  #
  class SpecificInterface < Interface
    attr_accessor :fake_input_queue

    def readline(_prompt)
      @fake_input_queue.pop
    end
  end

  #
  # Tests the Interface class
  #
  class InterfaceTest < Minitest::Test
    def setup
      @interface = SpecificInterface.new
    end

    def teardown
      @interface.history.clear
    end

    def test_reads_simple_commands
      @interface.fake_input_queue = ["a_command"]

      assert_equal "a_command", @interface.read_command("byebug")
    end

    def test_reads_multiple_commands_in_same_line_separated_by_semicolon
      @interface.fake_input_queue = ["a_command; another"]

      assert_equal "a_command", @interface.read_command("byebug")
      assert_equal "another", @interface.read_command("byebug")
    end

    def test_understands_ruby_commands_using_semicolon_if_escaped
      @interface.fake_input_queue = ['a_command \; another']

      assert_equal "a_command ; another", @interface.read_command("byebug")
    end

    def test_keeps_an_internal_command_buffer
      @interface.fake_input_queue = ["a_command"]
      @interface.command_queue = ["a_buffered_command"]

      assert_equal "a_buffered_command", @interface.read_command("byebug")
      assert_equal "a_command", @interface.read_command("byebug")
    end
  end
end
