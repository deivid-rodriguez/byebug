require 'timeout'
require 'test_helper'

module Byebug
  #
  # Tests generic input evaluation
  #
  class ProcessorBaseTest < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    byebug
        3:
        4:    d = 1
        5:    d += 1
        6:    d
        7:  end
      EOC
    end

    def test_empty_command_repeats_last_command
      enter 'n', ''

      debug_code(program) { assert_equal 6, frame.line }
    end

    def test_multiple_commands_are_executed_sequentially
      enter 'n ; n'

      debug_code(program) { assert_equal 6, frame.line }
    end

    def test_semicolon_can_be_escaped_to_prevent_multiple_command_behaviour
      enter 'n \; n'

      debug_code(program) { assert_equal 4, frame.line }
    end

    def test_shows_an_error_for_unknown_subcommands_by_default
      enter 'info unknown_subcmd'
      debug_code(minimal_program)

      check_error_includes(
        "Unknown command 'info unknown_subcmd'. Try 'help info'")
    end

    def test_properly_evaluates_expressions
      enter '3 + 2'
      debug_code(minimal_program)

      check_output_includes '5'
    end

    def test_is_invoked_on_unknown_input
      enter '[5, 6, 7].inject(&:+)'
      debug_code(minimal_program)

      check_output_includes '18'
    end

    def test_shows_backtrace_on_error_if_stack_on_error_enabled
      enter 'set stack_on_error', '2 / 0'
      debug_code(minimal_program)

      check_error_includes(/\s*from \S+:in \`eval\'/)
      check_error_doesnt_include 'ZeroDivisionError Exception: divided by 0'
    end

    def test_shows_only_exception_if_stack_on_error_disabled
      enter 'set stack_on_error off', '2 / 0'
      debug_code(minimal_program)

      check_error_includes 'ZeroDivisionError Exception: divided by 0'
      check_error_doesnt_include(/\S+:\d+:in `eval':divided by 0/)
    end
  end

  #
  # Tests evaluation in threaded programs.
  #
  class ProcessorEvaluationAndThreadsTestCase < TestCase
    def program
      <<-EOC
        module Byebug
          #
          # Toy class to test evaluation in Byebug's prompt
          #
          class #{example_class}
            attr_accessor :thread

            def initialize
              @thread = Thread.new do
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

          worker.thread.kill
        end
      EOC
    end

    def test_properly_evaluates_expressions_using_threads
      enter 'Timeout::timeout(60) { 1 }'
      debug_code(minimal_program)

      check_output_includes '1'
    end

    def test_does_not_hang_when_evaluating_expressions_using_new_threads
      enter 'Thread.new {}.join'
      debug_code(minimal_program)

      check_output_includes(/#<Thread:0x.*>/)
    end

    def test_does_not_hang_when_evaluating_expressions_using_old_threads
      enter 'worker.calc(10)'
      debug_code(program)

      check_output_includes '100'
    end
  end
end
