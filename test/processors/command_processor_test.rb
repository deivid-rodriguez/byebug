require 'timeout'
require 'test_helper'

module Byebug
  #
  # Tests generic command functionality.
  #
  class CommandProcessorTest < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    byebug
        3:
        4:    d = 1
        5:    d += 1
        6:    d
        7:  end
      EOC
    end

    def test_empty_command_repeats_last_command
      enter 'n', ''
      debug_code(program) { assert_equal 6, state.line }
    end

    def test_multiple_commands_are_executed_sequentially
      enter 'n ; n'
      debug_code(program) { assert_equal 6, state.line }
    end

    def test_semicolon_can_be_escaped_to_prevent_multiple_command_behaviour
      enter 'n \; n'
      debug_code(program) { assert_equal 4, state.line }
    end
  end
end
