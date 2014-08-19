module Byebug
  class EvalExample
    def sum(a,b)
      a + b
    end

    def inspect
      raise 'Broken'
    end
  end

  class EvalTestCase < TestCase
    def setup
      @example = -> do
        byebug
        @foo = EvalExample.new
        @foo.sum(1, 2)
      end

      super
    end

    %w(eval e p).each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_properly_evaluates_expressions") do
        enter 'eval 3 + 2'
        debug_proc(@example)
        check_output_includes '5'
      end
    end

    def test_eval_properly_evaluates_an_expression_using_timeout
      skip 'for now'
      enter 'eval Timeout::timeout(60) { 1 }'
      debug_proc(@example)
      check_output_includes '1'
    end

    def test_eval_works_when_inspect_raises_an_exception
      enter 'c 17', 'p @foo'
      debug_proc(@example) { assert_equal 17, state.line }
      check_output_includes 'RuntimeError Exception: Broken'
    end

    def test_autoeval_works_by_default
      enter '[5, 6 , 7].inject(&:+)'
      debug_proc(@example)
      check_output_includes '18'
    end

    def test_auto_eval_can_be_turned_off_and_back_on
      enter 'set noautoeval', '[5, 6, 7].inject(&:+)',
            'set autoeval',   '[1, 2, 3].inject(&:+)'
      debug_proc(@example)
      check_output_doesnt_include '18'
      check_output_includes '6'
    end

    def test_eval_shows_backtrace_on_error_if_stack_on_error_enabled
      enter 'set stack_on_error', 'eval 2 / 0'
      debug_proc(@example)
      check_output_includes(/\s*from \S+:in \`eval\'/)
      check_output_doesnt_include 'ZeroDivisionError Exception: divided by 0'
    end

    def test_eval_shows_only_exception_if_stack_on_error_disabled
      enter 'set stack_on_error off', 'eval 2 / 0'
      debug_proc(@example)
      check_output_includes 'ZeroDivisionError Exception: divided by 0'
      check_output_doesnt_include(/\S+:\d+:in `eval':divided by 0/)
    end

    def test_pp_pretty_print_the_expressions_result
      enter "pp { a: '3' * 40, b: '4' * 30 }"
      debug_proc(@example)
      check_output_includes "{:a=>\"#{'3' * 40}\",\n :b=>\"#{'4' * 30}\"}"
    end

    def test_putl_prints_expression_and_columnize_the_result
      enter 'set width 20', 'putl [1, 2, 3, 4, 5, 9, 8, 7, 6]'
      debug_proc(@example)
      check_output_includes "1  3  5  8  6\n2  4  9  7"
    end

    def test_putl_prints_expression_and_sorts_and_columnize_the_result
      enter 'set width 20', 'ps [1, 2, 3, 4, 5, 9, 8, 7, 6]'
      debug_proc(@example)
      check_output_includes "1  3  5  7  9\n2  4  6  8"
    end
  end
end
