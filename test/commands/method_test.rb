# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests commands for listing available methods.
  #
  class MethodTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test the method command.
         4:    #
         5:    class #{example_class}
         6:      def initialize
         7:        @a = "b"
         8:        @c = "d"
         9:      end
        10:
        11:      def self.foo
        12:        "asdf"
        13:      end
        14:
        15:      def bla
        16:        "asdf"
        17:      end
        18:    end
        19:
        20:    byebug
        21:
        22:    a = #{example_class}.new
        23:    a.bla
        24:  end
      RUBY
    end

    def test_method_shows_instance_methods_of_a_class
      enter "cont 7", "method #{example_class}"
      debug_code(program)

      check_output_includes("bla")
      check_output_doesnt_include("foo")
    end

    def test_m_shows_an_error_if_specified_object_is_not_a_class_or_module
      enter "m a"
      debug_code(program)

      check_output_includes "Should be Class/Module: a"
    end

    def test_method_instance_shows_methods_of_object
      enter "cont 23", "method instance a"
      debug_code(program)

      check_output_includes("bla")
      check_output_doesnt_include("foo")
    end
  end
end
