# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests gloabal variable untracing functionality.
  #
  class UntracevarTest < TestCase
    def test_untracevar_help
      enter "help untracevar"
      debug_code(minimal_program)

      check_output_includes "Stops tracing a global variable."
    end
  end
end
