require_relative 'test_helper'

class TestThread < TestDsl::TestCase
  let(:release) { 'eval Thread.main[:should_break] = true' }

  describe 'list' do
    it 'must show current thread by "plus" sign' do
      thnum = nil
      enter 'break 8', 'cont', 'thread list', release
      debug_file('thread') { thnum = Byebug.contexts.first.thnum }
      check_output_includes /\+ #{thnum} #<Thread:\S+ run>\t#{fullpath('thread')}:8/
    end

    it 'must work with shortcut' do
      thnum = nil
      enter 'break 8', 'cont', 'th list', release
      debug_file('thread') { thnum = Byebug.contexts.first.thnum }
      check_output_includes /\+ #{thnum} #<Thread:\S+ run>\t#{fullpath('thread')}:8/
    end

    it 'must show 3 available threads' do
      enter 'break 21', 'cont', 'thread list', release
      debug_file 'thread'
      check_output_includes /(\+)?\d+ #<Thread:\S+ (sleep|run)>/,
                            /(\+)?\d+ #<Thread:\S+ (sleep|run)>/,
                            /(\+)?\d+ #<Thread:\S+ (sleep|run)>/
    end
  end

  describe 'stop' do
    it 'must mark thread as suspended' do
      thnum = nil
      enter 'c 21', ->{ "thread stop #{Byebug.contexts.last.thnum}" }, release
      debug_file('thread') { thnum = Byebug.contexts.last.thnum }
      check_output_includes /\$ #{thnum} #<Thread:/
    end

    it 'must actually suspend thread execution' do
      enter 'c 21', 'trace on',
            ->{ "thread stop #{Byebug.contexts.last.thnum}" }, release
      debug_file('thread')
      check_output_doesnt_include /Tracing: #{fullpath('thread')}:16/,
                                  /Tracing: #{fullpath('thread')}:17/
    end

    it 'must show error message if thread number is not specified' do
      enter 'break 8', 'cont', 'thread stop', release
      debug_file 'thread'
      check_output_includes '"thread stop" needs a thread number',
                            interface.error_queue
    end

    it 'must show error message when trying to stop current thread' do
      enter 'cont 8', ->{"thread stop #{Byebug.contexts.first.thnum}"}, release
      debug_file 'thread'
      check_output_includes "It's the current thread", interface.error_queue
    end
  end

  describe 'resume' do
    it 'must mark remove thread from the suspended state' do
      thnum = nil
      enter 'cont 21',
            -> { thnum = Byebug.contexts.last.thnum ; "thread stop #{thnum}" },
            -> { "thread resume #{thnum}" }, release
      debug_file('thread') { Byebug.contexts.last.suspended?.must_equal false }
      check_output_includes /\$ #{thnum} #<Thread:/, /#{thnum} #<Thread:/
    end

    it 'must show error message if thread number is not specified' do
      enter 'break 8', 'cont', 'thread resume', release
      debug_file 'thread'
      check_output_includes '"thread resume" needs a thread number',
                            interface.error_queue
    end

    it 'must show error message when trying to resume current thread' do
      enter 'c 8', ->{ "thread resume #{Byebug.contexts.first.thnum}" }, release
      debug_file 'thread'
      check_output_includes "It's the current thread", interface.error_queue
    end

    it 'must show error message if it is not stopped' do
      enter 'c 21', ->{ "thread resume #{Byebug.contexts.last.thnum}" }, release
      debug_file 'thread'
      check_output_includes 'Already running', interface.error_queue
    end
  end
end
