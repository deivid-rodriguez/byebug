require_relative 'test_helper'

class FrameExample
  def initialize(f)
    @f = f
  end

  def a
    b
  end

  def b
    c
    2
  end

  def c
    d('a')
    3
  end

  def d(e)
    5
  end
end

class FrameDeepExample
  def a
    z = 1
    z += b
  end
  def b
    z = 2
    z += c
  end
  def c
    z = 3
    byebug
    z += d('a')
  end
  def d(e)
    4
  end
end

class TestFrame < TestDsl::TestCase
  describe 'when byebug started at the beginning' do
    before do
      @tst_file = fullpath('frame')
      enter "break #{__FILE__}:23", 'cont'
    end

    it 'must go up' do
      enter 'up'
      debug_file('frame') { $state.line.must_equal 18 }
    end

    it 'must go up by specific number of frames' do
      enter 'up 2'
      debug_file('frame') { $state.line.must_equal 13 }
    end

    it 'must go down' do
      enter 'up', 'down'
      debug_file('frame') { $state.line.must_equal 23 }
    end

    it 'must go down by specific number of frames' do
      enter 'up 3', 'down 2'
      debug_file('frame') { $state.line.must_equal 18 }
    end

    it 'must set frame' do
      enter 'frame 2'
      debug_file('frame') { $state.line.must_equal 13 }
    end

    it 'must print current stack frame when without arguments' do
      enter 'up', 'frame'
      debug_file('frame')
      check_output_includes(/#1  FrameExample\.c\s+at #{__FILE__}:18/)
    end

    it 'must set frame to the first one' do
      enter 'up', 'frame 0'
      debug_file('frame') { $state.line.must_equal 23 }
    end

    it 'must set frame to the last one' do
      enter 'frame -1'
      debug_file('frame') { $state.file.must_match(/minitest\/unit\.rb/) }
    end

    it 'must not set frame if the frame number is too low' do
      enter 'down'
      debug_file('frame') { $state.line.must_equal 23 }
      check_output_includes \
        "Can't navigate beyond the newest frame", interface.error_queue
    end

    it 'must not set frame if the frame number is too high' do
      enter 'up 100'
      debug_file('frame') { $state.line.must_equal 23 }
      check_output_includes \
        "Can't navigate beyond the oldest frame", interface.error_queue
    end

    describe 'fullpath' do
      describe 'when set' do
        temporary_change_hash Byebug.settings, :fullpath, true

        it 'must display current backtrace with fullpaths' do
          enter 'where'
          debug_file 'frame'
          check_output_includes(
            /--> #0  FrameExample\.d\(e#String\)\s+at #{__FILE__}:23/,
                /#1  FrameExample\.c\s+at #{__FILE__}:18/,
                /#2  FrameExample\.b\s+at #{__FILE__}:13/)
        end
      end

      describe 'when unset' do
        temporary_change_hash Byebug.settings, :fullpath, false

        it 'must display current backtrace with shortpaths' do
          enter 'where'
          debug_file 'frame'
          check_output_includes(
            /--> #0  FrameExample\.d\(e#String\)\s+at #{shortpath(__FILE__)}:23/,
                /#1  FrameExample\.c\s+at #{shortpath(__FILE__)}:18/,
                /#2  FrameExample\.b\s+at #{shortpath(__FILE__)}:13/,
                /#3  FrameExample\.a\s+at #{shortpath(__FILE__)}:9/)
        end
      end
    end

    describe 'callstyle' do
      describe 'long' do
        temporary_change_hash Byebug.settings, :callstyle, :long

        it 'displays current backtrace with callstyle "long"' do
          enter 'where'
          debug_file 'frame'
          check_output_includes(
            /--> #0  FrameExample\.d\(e#String\)\s+at #{__FILE__}:23/,
                /#1  FrameExample\.c\s+at #{__FILE__}:18/,
                /#2  FrameExample\.b\s+at #{__FILE__}:13/,
                /#3  FrameExample\.a\s+at #{__FILE__}:9/)
        end
      end

      describe 'short' do
        temporary_change_hash Byebug.settings, :callstyle, :short

        it 'displays current backtrace with callstyle "short"' do
            enter 'where'
            debug_file 'frame'
            check_output_includes(/--> #0  d\(e\)\s+at #{__FILE__}:23/,
                                      /#1  c\s+at #{__FILE__}:18/,
                                      /#2  b\s+at #{__FILE__}:13/,
                                      /#3  a\s+at #{__FILE__}:9/)
        end
      end
    end
  end

  describe 'when byebug is started deep in the callstack' do
    before { enter "break #{__FILE__}:42", 'cont' }

    it 'must print backtrace' do
      enter 'where'
      debug_file 'frame_deep'
      check_output_includes(
        /--> #0  FrameDeepExample\.d\(e#String\)\s+at #{__FILE__}:42/,
            /#1  FrameDeepExample\.c\s+at #{__FILE__}:39/,
            /#2  FrameDeepExample\.b\s+at #{__FILE__}:34/)
    end

    it 'must go up' do
      enter 'up'
      debug_file('frame_deep') { $state.line.must_equal 39 }
    end

    it 'must go down' do
      enter 'up', 'down'
      debug_file('frame_deep') { $state.line.must_equal 42 }
    end

    it 'must set frame' do
      enter 'frame 2'
      debug_file('frame_deep') { $state.line.must_equal 34 }
    end

    it 'must eval properly when scaling the stack' do
      enter 'p z', 'up', 'p z', 'up', 'p z'
      debug_file('frame_deep')
      check_output_includes 'nil', '3', '2'
    end
  end

  describe 'c-frames' do
    it 'must mark c-frames when printing the stack' do
      enter "break #{__FILE__}:5", 'cont', 'where'
      enter 'where'
      debug_file 'frame'
      check_output_includes(
        /--> #0  FrameExample.initialize\(f#String\)\s+at #{__FILE__}:5/,
            /ͱ-- #1  Class.new\(\*args\)\s+at #{fullpath('frame')}:3/,
            /#2  <top \(required\)>\s+at #{fullpath('frame')}:3/)
    end

    it '"up" skips c-frames' do
      enter "break #{__FILE__}:9", 'cont', 'up', 'eval fr_ex.class.to_s'
      debug_file 'frame'
      check_output_includes '"FrameExample"'
    end

    it '"down" skips c-frames' do
      enter "break #{__FILE__}:9", 'cont', 'up', 'down', 'eval @f'
      debug_file 'frame'
      check_output_includes '"f"'
    end

    it 'must not jump straigh to c-frames' do
      enter "break #{__FILE__}:5", 'cont', 'frame 1'
      debug_file 'frame'
      check_output_includes "Can't navigate to c-frame", interface.error_queue
    end
  end
end
