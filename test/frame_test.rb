require_relative 'test_helper'

class TestFrame < TestDsl::TestCase

  it 'must go up' do
    enter 'break 16', 'cont', 'up'
    debug_file('frame') { $state.line.must_equal 12 }
  end

  it 'must go up by specific number of frames' do
    enter 'break 16', 'cont', 'up 2'
    debug_file('frame') { $state.line.must_equal 8 }
  end

  it 'must go down' do
    enter 'break 16', 'cont', 'up', 'down'
    debug_file('frame') { $state.line.must_equal 16 }
  end

  it 'must go down by specific number of frames' do
    enter 'break 16', 'cont', 'up 3', 'down 2'
    debug_file('frame') { $state.line.must_equal 12 }
  end

  it 'must set frame' do
    enter 'break 16', 'cont', 'frame 2'
    debug_file('frame') { $state.line.must_equal 8 }
  end

  it 'must set frame to the first one by default' do
    enter 'break 16', 'cont', 'up', 'frame'
    debug_file('frame') { $state.line.must_equal 16 }
  end

  it 'must print current stack frame when without arguments' do
    enter 'break A.d', 'cont', 'up', 'frame'
    debug_file('frame')
    check_output_includes /#0  A.d(e#String) at #{fullpath('frame')}:15/x
  end

  it 'must set frame to the first one' do
    enter 'break 16', 'cont', 'up', 'frame 0'
    debug_file('frame') { $state.line.must_equal 16 }
  end

  it 'must set frame to the last one' do
    enter 'break 16', 'cont', 'bt', 'frame -1'
    debug_file('frame') { $state.file.must_match /minitest\/unit.rb/ }
    check_output_doesnt_include "at #{fullpath('frame')}:"
  end

  it 'must not set frame if the frame number is too low' do
    enter 'break 16', 'cont', 'down'
    debug_file('frame') { $state.line.must_equal 16 }
    check_output_includes \
      'Adjusting would put us beyond the newest (innermost) frame.',
      interface.error_queue
  end

  it 'must not set frame if the frame number is too high' do
    enter 'break 16', 'cont', 'up 100'
    debug_file('frame') { $state.line.must_equal 16 }
    check_output_includes \
      'Adjusting would put us beyond the oldest (initial) frame.',
      interface.error_queue
  end

  describe 'when byebug is started deep in the callstack' do
    it 'must print backtrace' do
      enter 'break 16', 'cont', 'where'
      debug_file 'frame_deep'
      check_output_includes \
        /--> #0  A.d(e#String) at #{fullpath('frame_deep')}:16/x,
            /#1  A.c at #{fullpath('frame_deep')}:13/x,
            /#2  A.b at #{fullpath('frame_deep')}:8/x
    end

    it 'must go up' do
      enter 'break 16', 'cont', 'up'
      debug_file('frame_deep') { $state.line.must_equal 13 }
    end

    it 'must go down' do
      enter 'break 16', 'cont', 'up', 'down'
      debug_file('frame_deep') { $state.line.must_equal 16 }
    end

    it 'must set frame' do
      enter 'break 16', 'cont', 'frame 2'
      debug_file('frame_deep') { $state.line.must_equal 8 }
    end

    it 'must eval properly when scaling the stack' do
      enter 'break 16', 'cont', 'p z', 'up', 'p z', 'up', 'p z'
      debug_file('frame_deep')
      check_output_includes 'nil', '3', '2'
    end
  end

  describe 'fullpath' do
    def short_path(fullpath)
      separator = File::ALT_SEPARATOR || File::SEPARATOR
      "...#{separator}" + fullpath.split(separator)[-3..-1].join(separator)
    end

    describe 'when set' do
      temporary_change_hash Byebug::Command.settings, :frame_fullpath, true

      it 'must display current backtrace with fullpaths' do
        enter 'break 16', 'cont', 'where'
        debug_file 'frame'
        check_output_includes \
          /--> #0  A.d(e#String) at #{fullpath('frame')}:16/x,
              /#1  A.c at #{fullpath('frame')}:12/x,
              /#2  A.b at #{fullpath('frame')}:8/x
      end
    end

    describe 'when unset' do
      temporary_change_hash Byebug::Command.settings, :frame_fullpath, false

      it 'must display current backtrace with shortpaths' do
        enter 'set nofullpath', 'break 16', 'cont', 'where'
        debug_file 'frame'
        check_output_includes \
          /--> #0  A.d(e#String) at #{short_path(fullpath('frame'))}:16/x,
              /#1  A.c at #{short_path(fullpath('frame'))}:12/x,
              /#2  A.b at #{short_path(fullpath('frame'))}:8/x
      end
    end
  end

  describe 'callstyle' do
    describe 'long' do
      temporary_change_hash Byebug::Command.settings, :callstyle, :long

      it 'displays current backtrace with callstyle "long"' do
        enter 'break 16', 'cont', 'where'
        debug_file 'frame'
        check_output_includes \
          /--> #0 A.d(e#String) at #{fullpath('frame')}:16/x,
              /#1 A.c at #{fullpath('frame')}:12/x          ,
              /#2 A.b at #{fullpath('frame')}:8/x           ,
              /#3 A.a at #{fullpath('frame')}:5/x
      end
    end

    describe 'short' do
      temporary_change_hash Byebug::Command.settings, :callstyle, :short

      it 'displays current backtrace with callstyle "short"' do
          enter 'break 16', 'cont', 'where'
          debug_file 'frame'
          check_output_includes /--> #0 d(e) at #{fullpath('frame')}:16/x,
                                    /#1 c at #{fullpath('frame')}:12/x,
                                    /#2 b at #{fullpath('frame')}:8/x,
                                    /#3 a at #{fullpath('frame')}:5/x
      end
    end
  end

  describe 'Post Mortem' do
    it 'must work in post-mortem mode' do
      enter 'cont', 'frame'
      debug_file('post_mortem') { $state.line.must_equal 8 }
    end
  end

end
