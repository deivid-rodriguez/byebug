module Byebug
  class IrbTestCase < TestCase
    def setup
      @example = -> do
        byebug
        a = 2
        a = 3
        a = 4
      end

      super

      interface.stubs(:kind_of?).with(LocalInterface).returns(true)
    end

    def test_irb_command_starts_an_irb_session
      IrbCommand.any_instance.expects(:execute)
      enter 'irb'
      debug_proc(@example)
    end

    def test_autoirb_calls_irb_automatically_after_every_stop
      IrbCommand.any_instance.expects(:execute)
      enter 'set autoirb', 'break 8', 'cont'
      debug_proc(@example)
    end
  end
end
