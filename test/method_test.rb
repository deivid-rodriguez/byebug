module Byebug
  class MethodExample
    def initialize
      @a = 'b'
      @c = 'd'
    end

    def self.foo
      'asdf'
    end

    def bla
      'asdf'
    end
  end

  class MethodTestCase < TestCase
    def setup
      @example = -> do
        byebug
        a = MethodExample.new
        a.bla
      end

      super
    end

    %w(method m).each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_shows_instance_methods_of_a_class") do
        enter 'break 4', 'cont', "#{cmd_alias} MethodExample"
        debug_proc(@example)
        check_output_includes(/bla/)
        check_output_doesnt_include(/foo/)
      end
    end

    def test_m_shows_an_error_if_specified_object_is_not_a_class_or_module
      enter 'm a'
      debug_proc(@example)
      check_output_includes 'Should be Class/Module: a'
    end

    ['method instance', 'm i'].each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_shows_methods_of_object") do
        enter 'break 22', 'cont', "#{cmd_alias} a"
        debug_proc(@example)
        check_output_includes(/bla/)
        check_output_doesnt_include(/foo/)
      end
    end
  end
end
