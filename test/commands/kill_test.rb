module Byebug
  class KillExample
    def self.kill_me
      'dieeee'
    end
  end

  class KillTestCase < TestCase
    def setup
      @example = -> do
        byebug
        KillExample.kill_me
      end

      super
    end

    def test_kill_sends_signal_to_some_pid
      Process.expects(:kill).with('USR1', Process.pid)
      enter 'kill USR1'
      debug_proc(@example)
    end

    def test_kill_closes_interface_when_sending_KILL_signal_explicitly
      Process.stubs(:kill).with('KILL', Process.pid)
      interface.expects(:close)
      enter 'kill KILL'
      debug_proc(@example)
    end

    def test_kill_asks_confirmation_when_sending_kill_implicitly
      Process.expects(:kill).with('KILL', Process.pid)
      enter 'kill', 'y'
      debug_proc(@example)
      check_confirm_includes 'Really kill? (y/n)'
    end

    def test_kill_does_not_send_an_unknown_signal
      Process.expects(:kill).with('BLA', Process.pid).never
      enter 'kill BLA'
      debug_proc(@example)
    end

    def test_kill_shows_an_error_when_the_signal_in_unknown
      enter 'kill BLA'
      debug_proc(@example)
      check_error_includes 'signal name BLA is not a signal I know about'
    end
  end
end
