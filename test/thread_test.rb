module ThreadTest
  class Example
    def initialize
      Thread.main[:should_break] = false
    end

    def launch
      @t1 = Thread.new do
        while true
          break if Thread.main[:should_break]
          sleep 0.02
        end
      end

      @t2 = Thread.new do
        while true
          sleep 0.02
        end
      end

      @t1.join
      Thread.main[:should_break]
    end

    def kill
      @t2.kill
    end
  end

  class ThreadTestCase < TestDsl::TestCase
    let(:release) { 'eval Thread.main[:should_break] = true' }

    before do
      @example = -> do
        byebug

        t = Example.new
        t.launch
        t.kill
      end
    end

    def first_thnum
      Byebug.contexts.first.thnum
    end

    def last_thnum
      Byebug.contexts.last.thnum
    end

    describe 'list' do
      it 'must show current thread by "plus" sign' do
        thnum = nil
        enter 'break 8', 'cont', 'thread list', release
        debug_proc(@example) { thnum = first_thnum }
        check_output_includes(/\+ #{thnum} #<Thread:\S+ run>\t#{__FILE__}:8/)
      end

      it 'must work with shortcut' do
        thnum = nil
        enter 'break 8', 'cont', 'th list', release
        debug_proc(@example) { thnum = first_thnum }
        check_output_includes(/\+ #{thnum} #<Thread:\S+ run>\t#{__FILE__}:8/)
      end

      it 'must show 3 available threads' do
        enter 'break 21', 'cont', 'thread list', release
        debug_proc(@example)
        check_output_includes(/(\+)?\d+ #<Thread:\S+ (sleep|run)>/,
                              /(\+)?\d+ #<Thread:\S+ (sleep|run)>/,
                              /(\+)?\d+ #<Thread:\S+ (sleep|run)>/)
      end
    end

    describe 'stop' do
      it 'must mark thread as suspended' do
        thnum = nil
        enter 'break 21', 'cont', ->{ "thread stop #{last_thnum}" }, release
        debug_proc(@example) { thnum = last_thnum }
        check_output_includes(/\$ #{thnum} #<Thread:/)
      end

      it 'must actually suspend thread execution' do
        enter 'break 21', 'cont', 'trace on',
              ->{ "thread stop #{last_thnum}" }, release
        debug_proc(@example)
        check_output_doesnt_include(/Tracing: #{__FILE__}:16/,
                                    /Tracing: #{__FILE__}:17/)
      end

      it 'must show error message if thread number is not specified' do
        enter 'break 8', 'cont', 'thread stop', release
        debug_proc(@example)
        check_error_includes '"thread stop" needs a thread number'
      end

      it 'must show error message when trying to stop current thread' do
        enter 'break 8', 'cont', -> { "thread stop #{first_thnum}" }, release
        debug_proc(@example)
        check_error_includes "It's the current thread"
      end
    end

    describe 'resume' do
      it 'must mark remove thread from the suspended state' do
        thnum = nil
        enter 'break 21', 'cont',
              -> { thnum = last_thnum ; "thread stop #{thnum}" },
              -> { "thread resume #{thnum}" }, release
        debug_proc(@example) { Byebug.contexts.last.suspended?.must_equal false }
        check_output_includes(/\$ #{thnum} #<Thread:/, /#{thnum} #<Thread:/)
      end

      it 'must show error message if thread number is not specified' do
        enter 'break 8', 'cont', 'thread resume', release
        debug_proc(@example)
        check_error_includes '"thread resume" needs a thread number'
      end

      it 'must show error message when trying to resume current thread' do
        enter 'break 8', 'cont', ->{ "thread resume #{first_thnum}" }, release
        debug_proc(@example)
        check_error_includes "It's the current thread"
      end

      it 'must show error message if it is not stopped' do
        enter 'break 21', 'cont', ->{ "thread resume #{last_thnum}" }, release
        debug_proc(@example)
        check_error_includes 'Already running'
      end
    end

    describe 'switch' do
      it 'must switch to another thread' do
        enter 'break 21', 'cont', ->{ "thread switch #{last_thnum}" }, release
        debug_proc(@example) { assert_equal state.line, 16 }
      end

      it 'must show error message if thread number is not specified' do
        enter 'break 8', 'cont', 'thread switch', release
        debug_proc(@example)
        check_error_includes '"thread switch" needs a thread number'
      end

      it 'must show error message when trying to switch current thread' do
        enter 'break 8', 'cont', ->{ "thread switch #{first_thnum}" }, release
        debug_proc(@example)
        check_error_includes "It's the current thread"
      end
    end
  end
end
