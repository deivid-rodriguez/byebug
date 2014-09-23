module Byebug
  class VariablesExample
    SOMECONST = 'foo' unless defined?(SOMECONST)

    def initialize
      @inst_a = 1
      @inst_b = 2
      @inst_c = '1' * 40
      @inst_d = BasicObject.new
    end

    def run
      a = 4
      b = [1, 2, 3].map do |i|
        a * i
      end
      b
    end
  end

  class VariablesTestCase < TestCase
    def setup
      @example = -> do
        byebug

        v = VariablesExample.new
        v.run
      end

      super
    end

    # TODO: we check a class minitest variable... brittle...
    ['var class', 'v cl'].each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_shows_class_variables") do
        enter cmd_alias
        debug_proc(@example)
        check_output_includes(/@@runnables/)
      end
    end

    ['var const', 'v co'].each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_shows_constants_in_class_or_module") do
        enter "#{cmd_alias} VariablesExample"
        debug_proc(@example)
        check_output_includes 'SOMECONST => "foo"'
      end
    end

    def test_var_const_shows_error_if_given_object_is_not_a_class_or_module
      enter 'var const v'
      debug_proc(@example)
      check_output_includes 'Should be Class/Module: v'
    end

    ['var global', 'v g'].each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_shows_global_variables") do
        enter cmd_alias
        debug_proc(@example)
        check_output_includes '$VERBOSE = true'
      end
    end

    ['var instance', 'v ins'].each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_shows_instance_vars_of_an_object") do
        enter 'break 27', 'cont', "#{cmd_alias} v"
        debug_proc(@example)
        check_output_includes '@inst_a = 1', '@inst_b = 2'
      end
    end

    def test_var_instance_shows_instance_variables_of_self_if_no_object_given
      enter 'break 9', 'cont', 'var instance'
      debug_proc(@example)
      check_output_includes '@inst_a = 1', '@inst_b = 2'
    end

    def test_var_instance_cuts_long_variable_values_according_to_width_setting
      enter 'break 27', 'cont', 'set width 45', 'var instance v'
      debug_proc(@example)
      check_output_includes '@inst_c = "1111111111111111111111111111111...'
    end

    def test_v_ins_shows_error_if_value_does_not_have_to_s_or_inspect_methods
      enter 'break 27', 'cont', 'v ins v'
      debug_proc(@example)
      check_output_includes '@inst_d = *Error in evaluation*'
    end

    def test_var_local_shows_local_variables
      enter 'break 15', 'cont', 'var local'
      debug_proc(@example)
      check_output_includes 'a => 4', 'b => nil', 'i => 1'
    end

    # TODO: class variables not currently checked
    ['var all', 'v a'].each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_shows_all_variables") do
        enter 'break 15', 'cont', cmd_alias
        debug_proc(@example)
        check_output_includes '$VERBOSE = true', '@inst_a = 1', 'a => 4'
      end
    end
  end
end
