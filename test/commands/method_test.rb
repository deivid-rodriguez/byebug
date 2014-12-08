module Byebug
  class MethodTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test the method command.
         4:    #
         5:    class #{example_class}
         6:      def initialize
         7:        @a = 'b'
         8:        @c = 'd'
         9:      end
        10:
        11:      def self.foo
        12:        'asdf'
        13:      end
        14:
        15:      def bla
        16:        'asdf'
        17:      end
        18:    end
        19:
        20:    byebug
        21:
        22:    a = #{example_class}.new
        23:    a.bla
        24:  end
      EOC
    end

    %w(method m).each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_shows_instance_methods_of_a_class") do
        enter 'cont 7', "#{cmd_alias} #{example_class}"
        debug_code(program)
        check_output_includes(/bla/)
        check_output_doesnt_include(/foo/)
      end
    end

    def test_m_shows_an_error_if_specified_object_is_not_a_class_or_module
      enter 'm a'
      debug_code(program)
      check_output_includes 'Should be Class/Module: a'
    end

    ['method instance', 'm i'].each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_shows_methods_of_object") do
        enter 'cont 23', "#{cmd_alias} a"
        debug_code(program)
        check_output_includes(/bla/)
        check_output_doesnt_include(/foo/)
      end
    end
  end
end
