require_relative 'test_helper'

class TestFrame < TestDsl::TestCase
  describe 'when byebug started at the beginning' do
    before do
      @tst_file = fullpath('frame')
      enter 'break 23', 'cont'
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
      check_output_includes /#1  FrameExample\.c\s+at #{@tst_file}:18/
    end

    it 'must set frame to the first one' do
      enter 'up', 'frame 0'
      debug_file('frame') { $state.line.must_equal 23 }
    end

    it 'must set frame to the last one' do
      enter 'frame -1'
      debug_file('frame') { $state.file.must_match /minitest\/unit.rb/ }
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
      def short_path(fullpath)
        separator = File::ALT_SEPARATOR || File::SEPARATOR
        "...#{separator}" + fullpath.split(separator)[-3..-1].join(separator)
      end

      describe 'when set' do
        temporary_change_hash Byebug.settings, :fullpath, true

        it 'must display current backtrace with fullpaths' do
          enter 'where'
          debug_file 'frame'
          check_output_includes \
            /--> #0  FrameExample\.d\(e#String\)\s+at #{@tst_file}:23/,
                /#1  FrameExample\.c\s+at #{@tst_file}:18/,
                /#2  FrameExample\.b\s+at #{@tst_file}:13/
        end
      end

      describe 'when unset' do
        temporary_change_hash Byebug.settings, :fullpath, false

        it 'must display current backtrace with shortpaths' do
          enter 'where'
          debug_file 'frame'
          check_output_includes \
            /--> #0  FrameExample\.d\(e#String\)\s+at #{short_path(@tst_file)}:23/,
                /#1  FrameExample\.c\s+at #{short_path(@tst_file)}:18/,
                /#2  FrameExample\.b\s+at #{short_path(@tst_file)}:13/,
                /#3  FrameExample\.a\s+at #{short_path(@tst_file)}:9/
        end
      end
    end

    describe 'callstyle' do
      describe 'long' do
        temporary_change_hash Byebug.settings, :callstyle, :long

        it 'displays current backtrace with callstyle "long"' do
          enter 'where'
          debug_file 'frame'
          check_output_includes \
            /--> #0  FrameExample\.d\(e#String\)\s+at #{@tst_file}:23/,
                /#1  FrameExample\.c\s+at #{@tst_file}:18/,
                /#2  FrameExample\.b\s+at #{@tst_file}:13/,
                /#3  FrameExample\.a\s+at #{@tst_file}:9/
        end
      end

      describe 'short' do
        temporary_change_hash Byebug.settings, :callstyle, :short

        it 'displays current backtrace with callstyle "short"' do
            enter 'where'
            debug_file 'frame'
            check_output_includes /--> #0  d\(e\)\s+at #{@tst_file}:23/,
                                      /#1  c\s+at #{@tst_file}:18/,
                                      /#2  b\s+at #{@tst_file}:13/,
                                      /#3  a\s+at #{@tst_file}:9/
        end
      end
    end
  end

  describe 'when byebug is started deep in the callstack' do
    before { @tst_file = fullpath('frame_deep') }

    it 'must print backtrace' do
      enter 'break 16', 'cont', 'where'
      debug_file 'frame_deep'
      check_output_includes \
        /--> #0  FrameDeepExample\.d\(e#String\)\s+at #{@tst_file}:16/,
            /#1  FrameDeepExample\.c\s+at #{@tst_file}:13/,
            /#2  FrameDeepExample\.b\s+at #{@tst_file}:8/
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

  describe 'c-frames (issue #10)' do
    before do
      @tst_file = fullpath('frame')
      enter 'break 5', 'cont'
    end

    it 'must mark c-frames when printing the stack' do
      enter 'where'
      debug_file 'frame'
      check_output_includes \
        /--> #0  FrameExample.initialize\(f#String\)\s+at #{@tst_file}:5/,
            /ͱ-- #1  Class.new\(\*args\)\s+at #{@tst_file}:28/,
            /#2  <top \(required\)>\s+at #{@tst_file}:28/
    end

    it 'must not navigate "up" to c-frames' do
      enter 'up', 'eval local_var'
      debug_file 'frame'
      check_output_includes '"hola"'
    end

    it 'must not navigate "down" to c-frames' do
      enter 'up', 'down', 'eval f'
      debug_file 'frame'
      check_output_includes '"f"'
    end

    it 'must not jump straigh to c-frames' do
      enter 'frame 1'
      debug_file 'frame'
      check_output_includes "Can't navigate to c-frame", interface.error_queue
    end
  end

  describe 'Post Mortem' do
    it 'must work in post-mortem mode' do
      enter 'cont', 'frame'
      debug_file('post_mortem') { $state.line.must_equal 8 }
    end
  end
end
