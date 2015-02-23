module Byebug
  #
  # Tests eval functionality.
  #
  class EvalTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test evaluation in Byebug's prompt
         4:    #
         5:    class #{example_class}
         6:      def sum(a, b)
         7:        a + b
         8:      end
         9:
        10:      def inspect
        11:        fail 'Broken'
        12:      end
        13:    end
        14:
        15:    byebug
        16:
        17:    @foo = #{example_class}.new
        18:    @foo.sum(1, 2)
        19:  end
      EOC
    end

    def test_eval_properly_evaluates_expressions
      enter 'eval 3 + 2'
      debug_code(program)
      check_output_includes '5'
    end

    def test_eval_properly_evaluates_expressions_using_threads
      require 'timeout'
      enter 'eval Timeout::timeout(60) { 1 }'
      debug_code(program)
      check_output_includes '1'
    end

    def test_eval_does_not_hang_when_evaluating_expressions_using_new_threads
      enter 'eval Thread.new {}.join'
      debug_code(program)
      check_output_includes(/#<Thread:0x.* dead>/)
    end

    def test_eval_works_when_inspect_raises_an_exception
      enter 'c 18', 'eval @foo'
      debug_code(program) { assert_equal 18, state.line }
      check_output_includes 'RuntimeError Exception: Broken'
    end

    def test_autoeval_works_by_default
      enter '[5, 6, 7].inject(&:+)'
      debug_code(program)
      check_output_includes '18'
    end

    def test_auto_eval_can_be_turned_off_and_back_on
      enter 'set noautoeval', '[5, 6, 7].inject(&:+)',
            'set autoeval', '[1, 2, 3].inject(&:+)'
      debug_code(program)
      check_output_doesnt_include '18'
      check_output_includes '6'
    end

    def test_eval_shows_backtrace_on_error_if_stack_on_error_enabled
      enter 'set stack_on_error', 'eval 2 / 0'
      debug_code(program)
      check_error_includes(/\s*from \S+:in \`eval\'/)
      check_output_doesnt_include 'ZeroDivisionError Exception: divided by 0'
    end

    def test_eval_shows_only_exception_if_stack_on_error_disabled
      enter 'set stack_on_error off', 'eval 2 / 0'
      debug_code(program)
      check_error_includes 'ZeroDivisionError Exception: divided by 0'
      check_output_doesnt_include(/\S+:\d+:in `eval':divided by 0/)
    end

    def test_pp_pretty_print_the_expressions_result
      enter "pp { a: '3' * 40, b: '4' * 30 }"
      debug_code(program)
      check_output_includes "{:a=>\"#{'3' * 40}\",", ":b=>\"#{'4' * 30}\"}"
    end

    def test_putl_prints_expression_and_columnize_the_result
      enter 'set width 20', 'putl [1, 2, 3, 4, 5, 9, 8, 7, 6]'
      debug_code(program)
      check_output_includes '1  3  5  8  6', '2  4  9  7'
    end

    def test_putl_prints_expression_and_sorts_and_columnize_the_result
      enter 'set width 20', 'ps [1, 2, 3, 4, 5, 9, 8, 7, 6]'
      debug_code(program)
      check_output_includes '1  3  5  7  9', '2  4  6  8'
    end

    def program_threads
      <<-EOC
        module Byebug
          #
          # Toy class to test evaluation in Byebug's prompt
          #
          class #{example_class}
            def initialize
              Thread.new do
                loop do
                  sleep 0.01
                  next if numbers.empty?
                  squares << (numbers.pop)**2
                end
              end
            end

            def numbers
              @numbers ||= Queue.new
            end

            def squares
              @squares ||= []
            end

            def calc(number)
              numbers.push(number)

              loop do
                next if squares.empty?

                return squares.pop
              end
            end
          end

          worker = #{example_class}.new

          byebug

          'Processed: ' + worker.squares.join(' ')
        end
      EOC
    end

    def test_eval_does_not_hang_when_evaluating_expressions_using_old_threads
      enter 'eval worker.calc(10)'
      debug_code(program_threads)
      check_output_includes '100'
    end
  end
end
