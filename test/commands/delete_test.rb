require 'test_helper'

module Byebug
  #
  # Tests deleting breakpoints.
  #
  class DeleteTest < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    #
        3:    # Toy class to test breakpoints
        4:    #
        5:    class #{example_class}
        6:      def add_two(n)
        7:        byebug
        8:        n += 1
        9:        n += 1
       10:        n
       11:      end
       12:    end
       13:
       14:    #{example_class}.new.add_two(0)
       15:  end
      EOC
    end

    def test_deleting_a_breakpoint_removes_it_from_breakpoints_list
      enter 'break 9', -> { "delete #{Breakpoint.first.id}" }

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    def test_deleting_a_breakpoint_shows_a_success_message
      enter 'break 9', -> { "delete #{Breakpoint.first.id}" }
      debug_code(program)

      check_output_includes(/Deleted breakpoint/)
    end

    def test_does_not_stop_at_the_deleted_breakpoint
      enter 'b 9', 'b 10', -> { "delete #{Breakpoint.first.id}" }, 'cont'

      debug_code(program) { assert_equal 10, frame.line }
    end

    def test_delete_by_itself_deletes_all_breakpoints_if_confirmed
      enter 'break 9', 'break 10', 'delete', 'y'

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    def test_delete_by_itself_keeps_current_breakpoints_if_not_confirmed
      enter 'break 9', 'break 10', 'delete', 'n'

      debug_code(program) { assert_equal 2, Byebug.breakpoints.size }
    end

    def test_delete_with_an_invalid_breakpoint_id_shows_error
      enter 'break 9', -> { "delete #{Breakpoint.last.id + 1}" }, 'cont'
      debug_code(program)

      check_error_includes(/No breakpoint number/)
    end
  end
end
