# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

module Byebug
  #
  # Tests exiting Byebug functionality.
  #
  class QuitTest < TestCase
    def faking_exit!
      Process.stub(:exit!, nil) { yield }
    end

    def test_quit_finishes_byebug_if_user_confirms
      faking_exit! do
        enter "quit", "y"
        debug_code(minimal_program)

        check_output_includes "Really quit? (y/n)"
      end
    end

    def test_quit_quits_inmediately_if_used_with_bang
      faking_exit! do
        enter "quit!"
        debug_code(minimal_program)

        check_output_doesnt_include "Really quit? (y/n)"
      end
    end

    def test_quit_quits_inmediately_if_used_with_unconditionally
      faking_exit! do
        enter "quit unconditionally"
        debug_code(minimal_program)

        check_output_doesnt_include "Really quit? (y/n)"
      end
    end

    def test_does_not_quit_if_user_did_not_confirm
      enter "quit", "n"
      debug_code(minimal_program)

      check_output_includes "Really quit? (y/n)"
    end
  end
end
