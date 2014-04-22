module FinishTest
  class Example
    def a
      b
    end

    def b
      c
      2
    end

    def c
      d
      3
    end

    def d
      5
    end
  end

  class FinishTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        Example.new.a
      end
      enter 'break 18', 'cont'
    end

    it 'must stop after current frame is finished when without arguments' do
      enter 'finish'
      debug_proc(@example) { state.line.must_equal 14 }
    end

    it 'must stop before current frame finishes if 0 specified as argument' do
      enter 'finish 0'
      debug_proc(@example) { state.line.must_equal 19 }
    end

    it 'must stop after current frame is finished if 1 specified as argument' do
      enter 'finish 1'
      debug_proc(@example) { state.line.must_equal 14 }
    end

    it 'must behave consistenly even if current frame has been changed' do
      enter 'up', 'finish'
      debug_proc(@example) { state.line.must_equal 9 }
    end

    describe 'not a number is specified for frame' do
      before { enter 'finish foo' }

      it 'must show an error' do
        debug_proc(@example)
        check_output_includes '"finish" argument "foo" needs to be a number'
      end

      it 'must be on the same line' do
        debug_proc(@example) { state.line.must_equal 18 }
      end
    end
  end
end
