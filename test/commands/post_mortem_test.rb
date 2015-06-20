require 'test_helper'

module Byebug
  #
  # Tests post mortem functionality.
  #
  class PostMortemTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test post mortem functionality
         4:    #
         5:    class #{example_class}
         6:      def a
         7:        fail 'blabla'
         8:      end
         9:    end
        10:
        11:    byebug
        12:
        13:    c = #{example_class}.new
        14:    c.a
        15:  end
      EOC
    end

    def test_rises_before_exit_in_post_mortem_mode
      with_setting :post_mortem, true do
        enter 'cont'

        assert_raises(RuntimeError) { debug_code(program) }
      end
    end

    def test_post_mortem_mode_sets_post_mortem_flag_to_true
      with_setting :post_mortem, true do
        enter 'cont'

        begin
          debug_code(program)
        rescue RuntimeError
          assert_equal true, Byebug.post_mortem?
        end
      end
    end

    def test_execution_is_stopped_at_the_correct_line_after_exception
      with_setting :post_mortem, true do
        enter 'cont'

        begin
          debug_code(program)
        rescue
          assert_equal 7, Byebug.raised_exception.__bb_line
        end
      end
    end

    forbidden = %w(step next finish break condition display tracevar untracevar)

    forbidden.each do |cmd|
      define_method "test_#{cmd}_is_forbidden_in_post_mortem_mode" do
        with_setting :post_mortem, true do
          enter 'set noautoeval', cmd, 'set autoeval'
          Context.any_instance.stubs(:dead?).returns(:true)

          begin
            debug_code(program)
          rescue RuntimeError
            check_error_includes 'Command unavailable in post mortem mode.'
          end
        end
      end
    end

    permitted = %w(restart frame quit edit info irb source help list method kill
                   eval set save show up where down)

    permitted.each do |cmd|
      define_method "test_#{cmd}_is_permitted_in_post_mortem_mode" do
        with_setting :post_mortem, true do
          enter cmd
          class_name = cmd.gsub(/(^| )\w/) { |b| b[-1, 1].upcase } + 'Command'

          Byebug.const_get(class_name).any_instance.stubs(:execute)
          assert_raises(RuntimeError) { debug_code(program) }
        end
      end
    end
  end
end
