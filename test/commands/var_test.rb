module Byebug
  #
  # Tests variable evaluation.
  #
  class VarTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test variable evaluation.
         4:    #
         5:    class #{example_class}
         6:      SOMECONST = 'foo' unless defined?(SOMECONST)
         7:      @@class_variable = 'bar'
         8:
         9:      def initialize
        10:        @instance_variable = '1' * 20
        11:        byebug
        12:        @empty_object = BasicObject.new
        13:      end
        14:
        15:      def run(level)
        16:        [1, 2, 3].map do |i|
        17:          level * i
        18:        end
        19:      end
        20:    end
        21:
        22:    v = #{example_class}.new
        23:    v.run(2)
        24:  end
      EOC
    end

    def test_var_class_shows_class_variables
      enter 'var class'
      debug_code(program)
      check_output_includes '@@class_variable = "bar"'
    end

    def test_var_const_shows_constants_in_class_or_module
      enter "var const Byebug::#{example_class}"
      debug_code(program)
      check_output_includes 'SOMECONST = foo'
    end

    def test_var_const_shows_error_if_given_object_is_not_a_class_or_module
      enter 'var const v'
      debug_code(program)
      check_output_includes 'Should be Class/Module: v'
    end

    def test_var_global_shows_global_variables
      enter 'var global'
      debug_code(program)
      check_output_includes '$ERROR_INFO = nil'
    end

    def test_var_instance_shows_instance_vars_of_an_object
      enter 'break 23', 'cont', 'var instance v'
      debug_code(program)
      check_output_includes '@instance_variable = "11111111111111111111"'
    end

    def test_var_instance_shows_instance_variables_of_self_if_no_object_given
      enter 'var instance'
      debug_code(program)
      check_output_includes '@instance_variable = "11111111111111111111"'
    end

    def test_var_instance_cuts_long_variable_values_according_to_width_setting
      enter 'set width 40', 'var instance'
      debug_code(program)
      check_output_includes '@instance_variable = "111111111111111...'
    end

    def test_v_ins_shows_error_if_value_does_not_have_to_s_or_inspect_methods
      enter 'break 23', 'cont', 'v ins v'
      debug_code(program)
      check_output_includes '@empty_object = *Error in evaluation*'
    end

    def test_var_local_shows_local_variables
      enter 'break 17', 'cont', 'var local'
      debug_code(program)
      check_output_includes 'level = 2', 'i = 1'
    end

    def test_var_all_shows_all_variables
      enter 'break 17', 'cont', 'var all'
      debug_code(program)
      check_output_includes '@@class_variable = "bar"',
                            '$ERROR_INFO = nil',
                            '@instance_variable = "11111111111111111111"',
                            'level = 2'
    end
  end
end
