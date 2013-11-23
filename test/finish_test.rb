class FinishExample
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

class TestFinish < TestDsl::TestCase
  before { enter "break #{__FILE__}:14", 'cont' }

  it 'must stop at the next frame by default' do
    enter 'finish'
    debug_file('finish') { state.line.must_equal 11 }
  end

  it 'must stop at the #0 frame by default' do
    enter 'finish 0'
    debug_file('finish') { state.line.must_equal 11 }
  end

  it 'must stop at the specified frame' do
    enter 'finish 1'
    debug_file('finish') { state.line.must_equal 7 }
  end

  it 'must stop at the next frame if the current frame was changed' do
    enter 'up', 'finish'
    debug_file('finish') { state.line.must_equal 7 }
  end

  describe 'not a number is specified for frame' do
    before { enter 'finish foo' }

    it 'must show an error' do
      debug_file('finish')
      check_output_includes '"finish" argument "foo" needs to be a number.'
    end

    it 'must be on the same line' do
      debug_file('finish') { state.line.must_equal 14 }
    end
  end
end
