# frozen_string_literal: true

require_relative "test_helper"

module Byebug
  #
  # Tests standalone byebug when debugging a target program
  #
  class RunnerAgainstProgramWithByebugCallTest < TestCase
    def setup
      super

      example_file.write("require 'byebug'\nbyebug\nsleep 0")
      example_file.close
    end

    def test_run_with_a_script_to_debug
      stdout = run_program(
        [RbConfig.ruby, example_path],
        'puts "Program: #{$PROGRAM_NAME}"'
      )

      assert_match(/Program: #{example_path}/, stdout)
    end
  end
end
