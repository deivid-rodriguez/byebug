# frozen_string_literal: true

require "test_helper"
require "timeout"

module Byebug
  #
  # Tests generic input evaluation
  #
  class ProcessorBaseTest < TestCase
    def program
      strip_line_numbers <<-RUBY
        1:  module Byebug
        2:    byebug
        3:
        4:    d = 1
        5:    d += 1
        6:    d
        7:  end
      RUBY
    end

    def test_syntax_error_gives_a_prompt_back
      enter "d."

      debug_code(program) { assert_equal 4, frame.line }
    end

    def test_empty_command_repeats_last_command
      enter "n", ""

      debug_code(program) { assert_equal 6, frame.line }
    end

    def test_multiple_commands_are_executed_sequentially
      enter "n ; n"

      debug_code(program) { assert_equal 6, frame.line }
    end

    def test_semicolon_can_be_escaped_to_prevent_multiple_command_behaviour
      enter 'n \; n'

      debug_code(program) { assert_equal 4, frame.line }
    end

    def test_shows_an_error_for_unknown_subcommands_by_default
      enter "info unknown_subcmd"
      debug_code(minimal_program)

      check_error_includes \
        "Unknown command 'info unknown_subcmd'. Try 'help info'"
    end
  end

  #
  # Test evaluation of unknown input introduced by the user. Basically, the
  # REPL behavior.
  #
  class ProcessorUnknownInputTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1: module Byebug
         2:   #
         3:   # Toy class to test evaluation of unknown input
         4:   #
         5:   class #{example_class}
         6:     def inspect
         7:       "A very cool string representation"
         8:     end
         9:
        10:     def to_s
        11:       "A not so cool string representation"
        12:     end
        13:   end
        14:
        15:   byebug
        16:
        17:   "Bye!"
        18: end
      RUBY
    end

    def test_arithmetic_expressions_are_evaluated_on_unknown_input
      enter "3 + 2"
      debug_code(minimal_program)

      check_output_includes "5"
    end

    def test_ruby_code_is_evaluated_on_unknown_input
      enter "[5, 6, 7].inject(&:+)"
      debug_code(minimal_program)

      check_output_includes "18"
    end

    def test_arrays_are_properly_printed_after_evaluation_of_unknown_input
      enter "(1..3).to_a"
      debug_code(minimal_program)

      check_output_includes "[1, 2, 3]"
    end

    def test_eval_evaluates_just_like_without_it
      enter 's = "something"', 'eval "s is #{s}"'

      debug_code(minimal_program)

      check_output_includes '"s is something"'
    end

    def test_evaluation_results_on_unknown_input_prefer_inspect_over_to_s
      enter "#{example_class}.new"
      debug_code(program)

      check_output_includes "A very cool string representation"
    end

    def test_shows_backtrace_on_error_if_stack_on_error_enabled
      enter "set stack_on_error", "2 / 0"
      debug_code(minimal_program)

      check_error_includes(/\s*from \S+:in \`eval\'/)
      check_error_doesnt_include "ZeroDivisionError Exception: divided by 0"
    end

    def test_shows_only_exception_if_stack_on_error_disabled
      enter "set stack_on_error off", "2 / 0"
      debug_code(minimal_program)

      check_error_includes "ZeroDivisionError Exception: divided by 0"
      check_error_doesnt_include(/\S+:\d+:in `eval':divided by 0/)
    end
  end

  #
  # Tests processor evaluation and breakpoints working together
  #
  class ProcessorEvaluationAndBreakpointsTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1: module Byebug
         2:   #
         3:   # Toy class to test subdebuggers inside evaluation prompt
         4:   #
         5:   class #{example_class}
         6:     def self.m1
         7:       m2
         8:     end
         9:
        10:     def self.m2
        11:       "m2"
        12:     end
        13:   end
        14:
        15:   byebug
        16:
        17:   #{example_class}.m1
        18:
        19:   "Bye!"
        20: end
      RUBY
    end

    def test_does_not_show_incorrect_info_about_having_stopped_at_breakpoint
      enter "b 7", "cont", "m2"
      debug_code(program)

      # Regular breakpoint: OK
      check_output_includes(/Stopped by breakpoint \d/)

      # Incorrect info when evaluating something from command prompt
      check_output_doesnt_include(/Stopped by breakpoint \d/,
                                  /Stopped by breakpoint \d/)
    end
  end

  #
  # Tests commands automatically run when control is returned back to user
  #
  class ProcessorAutocommandsTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1: module Byebug
         2:   #
         3:   # Toy class to test subdebuggers inside evaluation prompt
         4:   #
         5:   class #{example_class}
         6:     class_eval "def self.a; 1 end"
         7:   end
         8:
         9:   byebug
        10:
        11:   #{example_class}.a
        12:
        13:   "Bye!"
        14: end
      RUBY
    end

    def test_autolists_lists_source_before_stopping
      debug_code(program)

      check_output_includes "[5, 14] in #{example_path}"
    end

    def test_shows_error_when_current_source_location_is_unknown
      enter "step"

      debug_code(program) { assert_equal "(eval)", frame.file }
      check_error_includes "No sourcefile available for (eval)"
    end
  end

  #
  # Tests evaluation in threaded programs.
  #
  class ProcessorEvaluationAndThreadsTest < TestCase
    def program
      <<-RUBY
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
      RUBY
    end

    def test_properly_evaluates_expressions_using_threads
      enter "Timeout::timeout(60) { 1 }"
      debug_code(minimal_program)

      check_output_includes "1"
    end

    def test_does_not_hang_when_evaluating_expressions_using_new_threads
      enter "Thread.new {}.join"
      debug_code(minimal_program)

      check_output_includes(/#<Thread:0x.*>/)
    end

    def test_does_not_hang_when_evaluating_expressions_using_old_threads
      enter "worker.calc(10)"
      debug_code(program)

      check_output_includes "100"
    end

    def test_thread_context_is_kept
      enter 'Thread.current[:greeting] = "hi!"', "Thread.current[:greeting]"
      debug_code(minimal_program)

      check_output_includes '"hi!"', # After set
                            '"hi!"' # After get
    end
  end
end
