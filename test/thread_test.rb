require_relative 'test_helper'

class ThreadExample
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

class TestThread < TestDsl::TestCase
  let(:release) { 'eval Thread.main[:should_break] = true' }

  describe 'list' do
    it 'must show current thread by "plus" sign' do
      thnum = nil
      enter "break #{__FILE__}:9", 'cont', 'thread list', release
      debug_file('thread') { thnum = Byebug.contexts.first.thnum }
      check_output_includes(/\+ #{thnum} #<Thread:\S+ run>\t#{__FILE__}:9/)
    end

    it 'must work with shortcut' do
      thnum = nil
      enter "break #{__FILE__}:9", 'cont', 'th list', release
      debug_file('thread') { thnum = Byebug.contexts.first.thnum }
      check_output_includes(/\+ #{thnum} #<Thread:\S+ run>\t#{__FILE__}:9/)
    end

    it 'must show 3 available threads' do
      enter "break #{__FILE__}:22", 'cont', 'thread list', release
      debug_file 'thread'
      check_output_includes(/(\+)?\d+ #<Thread:\S+ (sleep|run)>/,
                            /(\+)?\d+ #<Thread:\S+ (sleep|run)>/,
                            /(\+)?\d+ #<Thread:\S+ (sleep|run)>/)
    end
  end

  describe 'stop' do
    it 'must mark thread as suspended' do
      thnum = nil
      enter "break #{__FILE__}:22", 'cont',
            ->{ "thread stop #{Byebug.contexts.last.thnum}" }, release
      debug_file('thread') { thnum = Byebug.contexts.last.thnum }
      check_output_includes(/\$ #{thnum} #<Thread:/)
    end

    it 'must actually suspend thread execution' do
      enter "break #{__FILE__}:22", 'cont', 'trace on',
            ->{ "thread stop #{Byebug.contexts.last.thnum}" }, release
      debug_file('thread')
      check_output_doesnt_include(/Tracing: #{__FILE__}:17/,
                                  /Tracing: #{__FILE__}:18/)
    end

    it 'must show error message if thread number is not specified' do
      enter "break #{__FILE__}:9", 'cont', 'thread stop', release
      debug_file 'thread'
      check_error_includes '"thread stop" needs a thread number'
    end

    it 'must show error message when trying to stop current thread' do
      enter "break #{__FILE__}:9", 'cont',
            ->{"thread stop #{Byebug.contexts.first.thnum}"}, release
      debug_file 'thread'
      check_error_includes "It's the current thread"
    end
  end

  describe 'resume' do
    it 'must mark remove thread from the suspended state' do
      thnum = nil
      enter "break #{__FILE__}:22", 'cont',
            -> { thnum = Byebug.contexts.last.thnum ; "thread stop #{thnum}" },
            -> { "thread resume #{thnum}" }, release
      debug_file('thread') { Byebug.contexts.last.suspended?.must_equal false }
      check_output_includes(/\$ #{thnum} #<Thread:/, /#{thnum} #<Thread:/)
    end

    it 'must show error message if thread number is not specified' do
      enter "break #{__FILE__}:9", 'cont', 'thread resume', release
      debug_file 'thread'
      check_error_includes '"thread resume" needs a thread number'
    end

    it 'must show error message when trying to resume current thread' do
      enter "break #{__FILE__}:9", 'cont',
            ->{ "thread resume #{Byebug.contexts.first.thnum}" }, release
      debug_file 'thread'
      check_error_includes "It's the current thread"
    end

    it 'must show error message if it is not stopped' do
      enter "break #{__FILE__}:22", 'cont',
            ->{ "thread resume #{Byebug.contexts.last.thnum}" }, release
      debug_file 'thread'
      check_error_includes 'Already running'
    end
  end

  describe 'switch' do
    it 'must switch to another thread' do
      enter "break #{__FILE__}:22", 'cont',
            ->{ "thread switch #{Byebug.contexts.last.thnum}" }, release
      debug_file('thread') { $state.line.must_equal 17 }
    end

    it 'must show error message if thread number is not specified' do
      enter "break #{__FILE__}:9", 'cont', 'thread switch', release
      debug_file 'thread'
      check_error_includes '"thread switch" needs a thread number'
    end

    it 'must show error message when trying to switch current thread' do
      enter "break #{__FILE__}:9", 'cont',
            ->{ "thread switch #{Byebug.contexts.first.thnum}" }, release
      debug_file 'thread'
      check_error_includes "It's the current thread"
    end
  end
end
