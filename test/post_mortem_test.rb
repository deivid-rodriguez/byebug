# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests post mortem functionality.
  #
  class PostMortemTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test post mortem functionality
         4:    #
         5:    class #{example_class}
         6:      def a
         7:        fail "blabla"
         8:      end
         9:    end
        10:
        11:    byebug
        12:
        13:    c = #{example_class}.new
        14:    c.a
        15:  end
      RUBY
    end

    def test_rises_before_exit_in_post_mortem_mode
      with_setting :post_mortem, true do
        enter "cont"

        assert_raises(RuntimeError) { debug_code(program) }
      end
    end

    def test_post_mortem_mode_sets_post_mortem_flag_to_true
      with_setting :post_mortem, true do
        enter "cont"

        begin
          debug_code(program)
        rescue RuntimeError
          assert_equal true, Byebug.post_mortem?
        end
      end
    end

    def test_execution_is_stopped_at_the_correct_line_after_exception
      with_setting :post_mortem, true do
        enter "cont"

        begin
          debug_code(program)
        rescue StandardError
          assert_equal 7, Byebug.raised_exception.__bb_context.frame.line
        end
      end
    end

    def test_command_forbidden_in_post_mortem_mode
      with_post_mortem_processor do
        with_setting :post_mortem, true do
          enter "help next"

          begin
            debug_code(program)
          rescue RuntimeError
            check_error_includes "Unknown command 'next'. Try 'help'"
          end
        end
      end
    end

    def test_command_permitted_in_post_mortem_mode
      with_post_mortem_processor do
        with_setting :post_mortem, true do
          enter "help where"

          begin
            debug_code(program)
          rescue RuntimeError
            check_output_includes "Displays the backtrace"
          end
        end
      end
    end

    private

    def with_post_mortem_processor
      old_processor = Context.processor
      Context.processor = PostMortemProcessor

      yield
    ensure
      Context.processor = old_processor
    end
  end
end
