module Byebug
  #
  # Tests deleting breakpoints.
  #
  class DeleteTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    #
        3:    # Toy class to test breakpoints
        4:    #
        5:    class TestExample
        6:      def add_two(n)
        7:        byebug
        8:        n += 1
        9:        n += 1
       10:        n
       11:      end
       12:    end
       13:
       14:    TestExample.new.add_two(0)
       15:  end
      EOC
    end

    def test_deleting_a_breakpoint_removes_it_from_breakpoints_list
      enter 'break 9', -> { "delete #{Breakpoint.first.id}" }

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    def test_does_not_stop_at_the_deleted_breakpoint
      enter 'b 9', 'b 10', -> { "delete #{Breakpoint.first.id}" }, 'cont'

      debug_code(program) { assert_equal 10, state.line }
    end
  end
end
