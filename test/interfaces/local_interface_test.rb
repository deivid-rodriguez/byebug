require 'byebug/runner'
require 'mocha/mini_test'

module Byebug
  class LocalInterfaceTest < Minitest::Test
    def setup
      @local_interface = LocalInterface.new
    end

    def test_readline_calls_out_to_std_lib_readline
      Readline.expects(:readline).returns("bar")
      result = @local_interface.readline ""

      assert_equal("bar", result)
    end

    def test_readline_prints_escape_sequence_on_interrupt
      Readline.stubs(:readline).raises(Interrupt, '').then.returns("")
      @local_interface.expects(:puts).with('^C')

      @local_interface.readline ""
    end

    def test_readline_retries_on_interrupt
      Readline.expects(:readline).twice.raises(Interrupt, '').then.returns("")
      @local_interface.stubs(:puts).with('^C')

      @local_interface.readline ""
    end
  end
end
