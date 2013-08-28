require_relative 'test_helper'

class TestFinish < TestDsl::TestCase

  it 'must stop at the next frame by default' do
    enter 'break 16', 'cont', 'finish'
    debug_file('finish') { $state.line.must_equal 13 }
  end

  it 'must stop at the #0 frame by default' do
    enter 'break 16', 'cont', 'finish 0'
    debug_file('finish') { $state.line.must_equal 13 }
  end

  it 'must stop at the specified frame' do
    enter 'break 16', 'cont', 'finish 1'
    debug_file('finish') { $state.line.must_equal 9 }
  end

  it 'must stop at the next frame if the current frame was changed' do
    enter 'break 16', 'cont', 'up', 'finish'
    debug_file('finish') { $state.line.must_equal 9 }
  end

  describe 'not a number is specified for frame' do
    before { enter 'break 16', 'cont', 'finish foo' }

    it 'must show an error' do
      debug_file('finish')
      check_output_includes '"finish" argument "foo" needs to be a number.'
    end

    it 'must be on the same line' do
      debug_file('finish') { $state.line.must_equal 16 }
    end
  end

  describe 'Post Mortem' do
    temporary_change_hash Byebug.settings, :autoeval, false

    it 'must not work in post-mortem mode' do
      enter 'cont', 'finish'
      debug_file 'post_mortem'
      check_output_includes \
        'Unknown command: "finish".  Try "help".', interface.error_queue
    end
  end

end
