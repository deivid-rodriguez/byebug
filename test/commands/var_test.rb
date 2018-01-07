# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests variable evaluation.
  #
  class VarTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test variable evaluation.
         4:    #
         5:    class #{example_class}
         6:      SOMECONST = "foo" unless defined?(SOMECONST)
         7:
         8:      def initialize
         9:        @instance_variable = "1" * 20
        10:        byebug
        11:      end
        12:
        13:      def run(level)
        14:        [1, 2, 3].map do |i|
        15:          level * i
        16:        end
        17:      end
        18:    end
        19:
        20:    v = #{example_class}.new
        21:    v.run(2)
        22:  end
      RUBY
    end

    def test_var_args_shows_information_about_current_frame_arguments
      enter "break 14", "cont", "var args"
      debug_code(program)

      check_output_includes "level = 2"
    end

    def test_var_const_shows_constants_in_class_or_module
      enter "var const Byebug::#{example_class}"
      debug_code(program)

      check_output_includes "SOMECONST = foo"
    end

    def test_var_const_shows_constants_in_current_scope_when_without_argument
      enter "var const"
      debug_code(program)

      check_output_includes "SOMECONST = foo"
    end

    def test_var_const_shows_error_if_given_object_is_not_a_class_or_module
      enter "break 21", "cont", "var const v"
      debug_code(program)

      check_error_includes "Should be Class/Module: v"
    end

    def test_var_instance_shows_instance_vars_of_an_object
      enter "break 21", "cont", "var instance v"
      debug_code(program)

      check_output_includes '@instance_variable = "11111111111111111111"'
    end

    def test_var_global_shows_global_variables
      enter "var global"
      debug_code(program)

      check_output_includes "$ERROR_INFO = nil"
    end

    def test_var_instance_shows_instance_variables_of_self_if_no_object_given
      enter "var instance"
      debug_code(program)

      check_output_includes '@instance_variable = "11111111111111111111"'
    end

    def test_var_instance_cuts_long_variable_values_according_to_width_setting
      with_setting :width, 40 do
        enter "var instance"
        debug_code(program)

        check_output_includes '@instance_variable = "111111111111111...'
      end
    end

    def test_var_local_shows_local_variables
      enter "break 15", "cont", "var local"
      debug_code(program)

      check_output_includes "i = 1", "level = 2"
    end

    def test_var_all_shows_all_variables
      enter "break 15", "cont", "var all"
      debug_code(program)

      check_output_includes "$ERROR_INFO = nil",
                            '@instance_variable = "11111111111111111111"',
                            "level = 2"
    end
  end
end
