module Byebug
  class DeleteTestCase < TestCase
    def setup
      @example = -> do
        byebug
        x = 1
        x += 1
        return x
      end

      super
    end

    def test_deleting_a_breakpoint_removes_it_from_breakpoints_list
      enter 'break 7', -> { "delete #{Breakpoint.first.id}" }

      debug_proc(@example) { assert_empty Byebug.breakpoints }
    end

    def test_does_not_stop_at_the_deleted_breakpoint
      enter 'b 7', 'b 8', -> { "delete #{Breakpoint.first.id}" }, 'cont'

      debug_proc(@example) { assert_equal 8, state.line }
    end
  end
end
