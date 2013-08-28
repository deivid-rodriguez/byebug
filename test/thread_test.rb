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
end
