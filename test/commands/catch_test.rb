# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests exception catching
  #
  class CatchTest < TestCase
    def test_catch_adds_catchpoints
      enter "catch NoMethodError"
      debug_code(minimal_program)

      assert_equal 1, Byebug.catchpoints.size
    end

    def test_catch_removes_specific_catchpoint
      enter "catch NoMethodError", "catch NoMethodError off"
      debug_code(minimal_program)

      assert_empty Byebug.catchpoints
    end

    def test_catch_off_removes_all_catchpoints_after_confirmation
      enter "catch NoMethodError", "catch off", "y"
      debug_code(minimal_program)

      assert_empty Byebug.catchpoints
    end

    def test_catch_without_arguments_and_no_exceptions_caught
      enter "catch"
      debug_code(minimal_program)

      check_output_includes "No exceptions set to be caught."
    end

    def test_catch_without_arguments_and_exceptions_caught
      enter "catch NoMethodError", "catch"
      debug_code(minimal_program)

      check_output_includes "NoMethodError: false"
    end

    def test_catch_help
      enter "help catch"
      debug_code(minimal_program)

      check_output_includes "cat[ch][ (off|<exception>[ off])]"
    end
  end
end
