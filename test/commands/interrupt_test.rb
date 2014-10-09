module Byebug
  #
  # Tests interrupt command.
  #
  class InterruptTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    byebug
         3:
         4:    ex = 0
         5:
         6:    1.times do
         7:      ex += 1
         8:    end
         9:  end
      EOC
    end

    def test_interrupt_stops_at_the_next_statement
      enter 'interrupt', 'continue'
      debug_code(program) { assert_equal 6, state.line }
    end

    def test_interrupt_steps_into_blocks
      enter 'next', 'interrupt', 'continue'
      debug_code(program) { assert_equal 7, state.line }
    end
  end
end
