module ContinueTest
  class Example
    def self.a(num)
      num + 4
    end
  end

  class ContinueTestCase < TestDsl::TestCase
    before do
      @example = lambda do
        byebug

        b = 5
        c = b + 5
        Example.a(c)
      end
    end

    describe 'successful' do
      it 'must continue up to breakpoint if no line specified' do
        enter 'break 14', 'continue'
        debug_proc(@example) { state.line.must_equal 14 }
      end

      it 'must work in abbreviated mode too' do
        enter 'break 14', 'cont'
        debug_proc(@example) { state.line.must_equal 14 }
      end

      it 'must continue up to specified line' do
        enter 'cont 14'
        debug_proc(@example) { state.line.must_equal 14 }
      end
    end

    describe 'unsuccessful' do
      before { enter 'cont 100' }

      it 'must ignore the command if specified line is not valid' do
        debug_proc(@example) { state.line.must_equal 13 }
      end

      it 'must show error if specified line is not valid' do
        debug_proc(@example)
        check_error_includes \
          "Line 100 is not a stopping point in file \"#{__FILE__}\""
      end
    end
  end
end
