require 'mocha/mini_test'
require 'test_helper'

module Byebug
  #
  # Test signal sending functionality.
  #
  class KillTest < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test signals
         4:    #
         5:    class #{example_class}
         6:      def self.kill_me
         7:        'dieeee'
         8:      end
         9:    end
        10:
        11:    byebug
        12:
        13:    #{example_class}.kill_me
        14:  end
      EOC
    end

    def test_kill_sends_signal_to_some_pid
      Process.expects(:kill).with('TERM', Process.pid)
      enter 'kill TERM'
      debug_code(program)
    end

    def test_kill_closes_interface_when_sending_kill_signal_explicitly
      Process.stubs(:kill).with('KILL', Process.pid)
      interface.expects(:close)
      enter 'kill KILL'
      debug_code(program)
    end

    def test_kill_asks_confirmation_when_sending_kill_implicitly
      Process.expects(:kill).with('KILL', Process.pid)
      enter 'kill', 'y'
      debug_code(program)
      check_output_includes 'Really kill? (y/n)'
    end

    def test_kill_does_not_send_an_unknown_signal
      Process.expects(:kill).with('BLA', Process.pid).never
      enter 'kill BLA'
      debug_code(program)
    end

    def test_kill_shows_an_error_when_the_signal_in_unknown
      enter 'kill BLA'
      debug_code(program)
      check_error_includes 'signal name BLA is not a signal I know about'
    end
  end
end
