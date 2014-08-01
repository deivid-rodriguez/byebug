module Byebug
  class InterruptExample
    def self.a(num)
      num += 2
      b(num)
    end

    def self.b(num)
      v2 = 5 if 1 == num ; [1, 2, v2].map { |a| a.to_f }
      c(num)
    end

    def self.c(num)
      num += 4
      num
    end
  end

  class InterruptTestCase < TestCase
    def setup
      @example = -> do
        byebug
        ex = InterruptExample.a(7)
        2.times do
          ex += 1
        end
        InterruptExample.b(ex)
      end

      super
    end

    def test_interrupt_stops_at_the_next_statement
      enter 'interrupt', 'continue'
      debug_proc(@example) do
        assert_equal [__FILE__, 4], [state.file, state.line]
      end
    end

    def test_interrupt_steps_into_blocks
      enter 'break 24', 'cont', 'interrupt', 'cont'
      debug_proc(@example) { assert_equal 25, state.line }
    end
  end
end
