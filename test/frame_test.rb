module FrameTest
  class Example
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

  class DeepExample
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

  class FrameTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        fr_ex = Example.new('f')
        fr_ex.a()
      end
    end

    describe 'when byebug started at the beginning' do
      before do
        enter "break #{__FILE__}:18", 'cont'
      end

      it 'must go up' do
        enter 'up'
        debug_proc(@example) { state.line.must_equal 14 }
      end

      it 'must go up by specific number of frames' do
        enter 'up 2'
        debug_proc(@example) { state.line.must_equal 10 }
      end

      it 'must go down' do
        enter 'up', 'down'
        debug_proc(@example) { state.line.must_equal 18 }
      end

      it 'must go down by specific number of frames' do
        enter 'up 3', 'down 2'
        debug_proc(@example) { state.line.must_equal 14 }
      end

      it 'must set frame' do
        enter 'frame 2'
        debug_proc(@example) { state.line.must_equal 10 }
      end

      it 'must print current stack frame when without arguments' do
        enter 'up', 'frame'
        debug_proc(@example)
        check_output_includes(/#1  FrameTest::Example\.c\s+at #{__FILE__}:14/)
      end

      it 'must set frame to the first one' do
        enter 'up', 'frame 0'
        debug_proc(@example) { state.line.must_equal 18 }
      end

      it 'must set frame to the last one' do
        enter 'frame -1'
        debug_proc(@example) { File.basename(state.file).must_equal 'test_helper.rb' }
      end

      it 'must not set frame if the frame number is too low' do
        enter 'down'
        debug_proc(@example) { state.line.must_equal 18 }
        check_output_includes \
          "Can't navigate beyond the newest frame", interface.error_queue
      end

      it 'must not set frame if the frame number is too high' do
        enter 'up 100'
        debug_proc(@example) { state.line.must_equal 18 }
        check_output_includes \
          "Can't navigate beyond the oldest frame", interface.error_queue
      end

      describe 'fullpath' do
        describe 'when set' do
          temporary_change_hash Byebug::Setting, :fullpath, true

          it 'must display current backtrace with fullpaths' do
            enter 'where'
            debug_proc(@example)
            check_output_includes(
              /--> #0  FrameTest::Example\.d\(e#String\)\s+at #{__FILE__}:18/,
                  /#1  FrameTest::Example\.c\s+at #{__FILE__}:14/,
                  /#2  FrameTest::Example\.b\s+at #{__FILE__}:10/,
                  /#3  FrameTest::Example\.a\s+at #{__FILE__}:7/)
          end
        end

        describe 'when unset' do
          temporary_change_hash Byebug::Setting, :fullpath, false

          it 'must display current backtrace with shortpaths' do
            path = shortpath(__FILE__)
            enter 'where'
            debug_proc(@example)
            check_output_includes(
              /--> #0  FrameTest::Example\.d\(e#String\)\s+at #{path}:18/,
                  /#1  FrameTest::Example\.c\s+at #{path}:14/,
                  /#2  FrameTest::Example\.b\s+at #{path}:10/,
                  /#3  FrameTest::Example\.a\s+at #{path}:7/)
          end
        end
      end

      describe 'callstyle' do
        describe 'long' do
          temporary_change_hash Byebug::Setting, :callstyle, :long

          it 'displays current backtrace with callstyle "long"' do
            enter 'where'
            debug_proc(@example)
            check_output_includes(
              /--> #0  FrameTest::Example\.d\(e#String\)\s+at #{__FILE__}:18/,
                  /#1  FrameTest::Example\.c\s+at #{__FILE__}:14/,
                  /#2  FrameTest::Example\.b\s+at #{__FILE__}:10/,
                  /#3  FrameTest::Example\.a\s+at #{__FILE__}:7/)
          end
        end

        describe 'short' do
          temporary_change_hash Byebug::Setting, :callstyle, :short

          it 'displays current backtrace with callstyle "short"' do
              enter 'where'
              debug_proc(@example)
              check_output_includes(/--> #0  d\(e\)\s+at #{__FILE__}:18/,
                                        /#1  c\s+at #{__FILE__}:14/,
                                        /#2  b\s+at #{__FILE__}:10/,
                                        /#3  a\s+at #{__FILE__}:7/)
          end
        end
      end
    end

    describe 'when byebug is started deep in the callstack' do
      before do
        @deep_example = -> do
          DeepExample.new.a
        end
        enter "break #{__FILE__}:37", 'cont'
      end

      it 'must print backtrace' do
        enter 'where'
        debug_proc(@deep_example)
        check_output_includes(
          /--> #0  FrameTest::DeepExample\.d\(e#String\)\s+at #{__FILE__}:37/,
              /#1  FrameTest::DeepExample\.c\s+at #{__FILE__}:34/,
              /#2  FrameTest::DeepExample\.b\s+at #{__FILE__}:29/)
      end

      it 'must go up' do
        enter 'up'
        debug_proc(@deep_example) { state.line.must_equal 34 }
      end

      it 'must go down' do
        enter 'up', 'down'
        debug_proc(@deep_example) { state.line.must_equal 37 }
      end

      it 'must set frame' do
        enter 'frame 2'
        debug_proc(@deep_example) { state.line.must_equal 29 }
      end

      it 'must eval properly when scaling the stack' do
        enter 'p z', 'up', 'p z', 'up', 'p z'
        debug_proc(@deep_example)
        check_output_includes 'nil', '3', '2'
      end
    end

    describe 'c-frames' do
      it 'must mark c-frames when printing the stack' do
        file = __FILE__
        enter "break #{__FILE__}:4", 'cont', 'where'
        enter 'where'
        debug_proc(@example)
        check_output_includes(
          /--> #0  FrameTest::Example.initialize\(f#String\)\s+at #{file}:4/,
              /ͱ-- #1  Class.new\(\*args\)\s+at #{file}:45/,
              /#2  block \(2 levels\) in <class:FrameTestCase>\s+at #{file}:45/)
      end

      it '"up" skips c-frames' do
        enter "break #{__FILE__}:7", 'cont', 'up', 'eval fr_ex.class.to_s'
        debug_proc(@example)
        check_output_includes '"FrameTest::Example"'
      end

      it '"down" skips c-frames' do
        enter "break #{__FILE__}:7", 'cont', 'up', 'down', 'eval @f'
        debug_proc(@example)
        check_output_includes '"f"'
      end

      it 'must not jump straigh to c-frames' do
        enter "break #{__FILE__}:4", 'cont', 'frame 1'
        debug_proc(@example)
        check_output_includes "Can't navigate to c-frame", interface.error_queue
      end
    end
  end
end
