class TestConditions < TestDsl::TestCase

  describe 'setting condition' do
    before { enter 'break 3' }

    describe 'successfully' do
      before { enter ->{ "cond #{Byebug.breakpoints.first.id} b == 5" }, 'cont'}

      it 'must assign the expression to breakpoint' do
        debug_file('conditions') {
          Byebug.breakpoints.first.expr.must_equal 'b == 5' }
      end

      it 'must stop at the breakpoint if condition is true' do
        debug_file('conditions') { state.line.must_equal 3 }
      end

      it 'must work with full command name too' do
        debug_file('conditions') { state.line.must_equal 3 }
      end
    end

    describe 'unsuccessfully' do
      before { enter 'break 4' }

      it 'must not stop at the breakpoint if condition is false' do
        enter ->{ "cond #{Byebug.breakpoints.first.id} b == 3" }, 'cont'
        debug_file('conditions') { state.line.must_equal 4 }
      end

      it 'must assign expression to breakpoint in spite of incorrect syntax' do
        enter ->{ "cond #{Byebug.breakpoints.first.id} b =="}, 'cont'
        debug_file('conditions') {
          Byebug.breakpoints.first.expr.must_equal 'b ==' }
      end

      it 'must ignore the condition if when incorrect syntax' do
        enter ->{ "cond #{Byebug.breakpoints.first.id} b ==" },  'cont'
        debug_file('conditions') { state.line.must_equal 4 }
      end
    end
  end

  describe 'removing conditions' do
    before { enter 'break 3 if b == 3', 'break 4',
                   ->{"cond #{Byebug.breakpoints.first.id}"}, 'cont' }

    it 'must remove the condition from the breakpoint' do
      debug_file('conditions') { Byebug.breakpoints.first.expr.must_be_nil }
    end

    it 'must unconditionally stop on the breakpoint' do
      debug_file('conditions') { state.line.must_equal 3 }
    end
  end

  describe 'errors' do
    it 'must show error if there are no breakpoints' do
      enter 'cond 1 true'
      debug_file('conditions')
      check_output_includes 'No breakpoints have been set.'
    end

    it 'must not set breakpoint condition if breakpoint id is incorrect' do
      enter 'break 3', 'cond 8 b == 3', 'cont'
      debug_file('conditions') { state.line.must_equal 3 }
    end
  end
end
