module ConditionsTest
  class ConditionsTestCase < TestDsl::TestCase
    before do
      @example = lambda do
        byebug
        b = 5
        c = b + 5
        c = Object.new
      end
    end

    def first
      Byebug.breakpoints.first
    end

    describe 'setting condition' do
      before { enter 'break 7' }

      describe 'successfully' do
        before { enter ->{ "cond #{first.id} b == 5" }, 'cont' }

        it 'must assign the expression to breakpoint' do
          debug_proc(@example) { first.expr.must_equal 'b == 5' }
        end

        it 'must stop at the breakpoint if condition is true' do
          debug_proc(@example) { state.line.must_equal 7 }
        end

        it 'must work with full command name too' do
          debug_proc(@example) { state.line.must_equal 7 }
        end
      end

      describe 'unsuccessfully' do
        before { enter 'break 8' }

        it 'must not stop at the breakpoint if condition is false' do
          enter ->{ "cond #{first.id} b == 3" }, 'cont'
          debug_proc(@example) { state.line.must_equal 8 }
        end

        it 'must assign expression to breakpoint in spite of incorrect syntax' do
          enter ->{ "cond #{first.id} b =="}, 'cont'
          debug_proc(@example) { first.expr.must_equal 'b ==' }
        end

        it 'must ignore the condition if when incorrect syntax' do
          enter ->{ "cond #{first.id} b ==" },  'cont'
          debug_proc(@example) { state.line.must_equal 8 }
        end
      end
    end

    describe 'removing conditions' do
      before do
        enter 'break 7 if b == 3', 'break 8', -> { "cond #{first.id}" }, 'cont'
      end

      it 'must remove the condition from the breakpoint' do
        debug_proc(@example) { first.expr.must_be_nil }
      end

      it 'must unconditionally stop on the breakpoint' do
        debug_proc(@example) { state.line.must_equal 7 }
      end
    end

    describe 'errors' do
      it 'must show error if there are no breakpoints' do
        enter 'cond 1 true'
        debug_proc(@example)
        check_output_includes 'No breakpoints have been set.'
      end

      it 'must not set breakpoint condition if breakpoint id is incorrect' do
        enter 'break 7', 'cond 8 b == 3', 'cont'
        debug_proc(@example) { state.line.must_equal 7 }
      end
    end
  end
end
