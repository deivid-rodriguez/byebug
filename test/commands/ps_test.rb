require 'test_helper'

module Byebug
  #
  # Tests enhanced evaluation functionality.
  #
  class PsTest < TestCase
    def test_properly_evaluates_expressions
      enter 'ps 3 + 2'
      debug_code(minimal_program)

      check_output_includes '5'
    end

    def test_sorts_and_prettyprints_arrays
      enter 'ps Kernel.instance_methods'
      debug_code(minimal_program)

      check_output_includes(':byebug,', ':class,')
    end
  end
end
