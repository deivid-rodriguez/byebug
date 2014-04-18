module KillTest
  class Example
    def self.kill_me
      'dieeee'
    end
  end

  class KillTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        Example.kill_me
      end
    end

    it 'must send signal to some pid' do
      Process.expects(:kill).with('USR1', Process.pid)
      enter 'kill USR1'
      debug_proc(@example)
    end

    it 'must close interface when sending KILL signal explicitly' do
      Process.stubs(:kill).with('KILL', Process.pid)
      interface.expects(:close)
      enter 'kill KILL'
      debug_proc(@example)
    end

    it 'must ask confirmation when sending KILL implicitly' do
      Process.expects(:kill).with('KILL', Process.pid)
      enter 'kill', 'y'
      debug_proc(@example)
      check_output_includes 'Really kill? (y/n)', interface.confirm_queue
    end

    describe 'unknown signal' do
      it 'must not send the signal' do
        Process.expects(:kill).with('BLA', Process.pid).never
        enter 'kill BLA'
        debug_proc(@example)
      end

      it 'must show an error' do
        enter 'kill BLA'
        debug_proc(@example)
        check_error_includes 'signal name BLA is not a signal I know about'
      end
    end
  end
end
