module Byebug
  class IrbTestCase < TestCase
    def setup
      @example = -> do
        byebug
        a = 2
        a = 3
        a = 4
        a = 5
        a = 6
      end

      super

      interface.stubs(:kind_of?).with(LocalInterface).returns(true)
      IRB::Irb.stubs(:new).returns(irb)
    end

    def irb
      @irb ||= stub(context: -> {})
    end

    def test_irb_supports_next_command
      irb.stubs(:eval_input).throws(:IRB_EXIT, :next)
      enter 'irb'
      debug_proc(@example) { assert_equal 7, state.line }
    end

    def test_irb_supports_step_command
      irb.stubs(:eval_input).throws(:IRB_EXIT, :step)
      enter 'irb'
      debug_proc(@example) { assert_equal 7, state.line }
    end

    def test_irb_supports_cont_command
      irb.stubs(:eval_input).throws(:IRB_EXIT, :cont)
      enter 'break 8', 'irb'
      debug_proc(@example) { assert_equal 8, state.line }
    end

    def test_autoirb_calls_irb_automatically_after_every_stop
      irb.expects(:eval_input)
      enter 'set autoirb', 'break 8', 'cont'
      debug_proc(@example)
    end
  end
end
