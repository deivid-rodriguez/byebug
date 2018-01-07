# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Test signal sending functionality.
  #
  class KillTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test signals
         4:    #
         5:    class #{example_class}
         6:      def self.kill_me
         7:        "dieeee"
         8:      end
         9:    end
        10:
        11:    byebug
        12:
        13:    #{example_class}.kill_me
        14:  end
      RUBY
    end

    def test_kill_sends_signal_to_some_pid
      assert_calls(Process, :kill, "TERM #{Process.pid}") do
        enter "kill TERM"
        debug_code(program)
      end
    end

    def test_kill_closes_interface_when_sending_kill_signal_explicitly
      Process.stub(:kill, nil) do
        assert_calls(interface, :close) do
          enter "kill KILL"
          debug_code(program)
        end
      end
    end

    def test_kill_asks_confirmation_when_sending_kill_implicitly
      assert_calls(Process, :kill, "KILL #{Process.pid}") do
        enter "kill", "y"
        debug_code(program)

        check_output_includes "Really kill? (y/n)"
      end
    end

    def test_kill_does_not_send_an_unknown_signal
      refute_calls(Process, :kill, "BLA #{Process.pid}") do
        enter "kill BLA"
        debug_code(program)
      end
    end

    def test_kill_shows_an_error_when_the_signal_is_unknown
      enter "kill BLA"
      debug_code(program)

      check_error_includes "signal name BLA is not a signal I know about"
    end
  end
end
