# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests expression evaluation.
  #
  class EvalTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    Foo = "Foo constant"
         3:    foo = :foo_variable
         4:    byebug
         5:  end
      RUBY
    end

    def test_eval_prints_values
      enter "Foo", "foo"
      debug_code(program)
      check_output_includes('"Foo constant"')
      check_output_includes(":foo_variable")
    end
  end

  #
  # Tests expression evalution of the code that uses TracePoint.
  #
  class EvalTracePointClassTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  result = :tp_class_not_called
         2:  autoload :Foo, "./foo"
         3:  TracePoint.new(:class) { |tp| result = :tp_class_called }.enable
         4:  byebug
         5:  result
      RUBY
    end

    def foo_program
      strip_line_numbers <<-RUBY
         1:  module Foo
         2:    def self.bar
         3:      "Foo.bar called"
         4:    end
         5:  end
      RUBY
    end

    def test_eval_triggers_class_tracepoint
      skip unless TracePoint.respond_to?(:allow_reentry) # TracePoint.allow_reentry only supported in >= 3.1

      with_new_file("foo.rb", foo_program) do
        enter "Foo.bar", "result"
        debug_code(program)
        check_output_includes('"Foo.bar called"')
        check_output_includes(":tp_class_called")
      end
    end
  end
end
