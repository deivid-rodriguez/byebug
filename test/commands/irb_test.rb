# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

module Byebug
  #
  # Tests entering IRB from within Byebug.
  #
  class IrbTest < TestCase
    def program
      strip_line_numbers <<-RUBY
        1:  module Byebug
        2:    byebug
        3:
        4:    a = 2
        5:    a + 4
        6:  end
      RUBY
    end

    def test_irb_command_starts_an_irb_session
      interface.stub(:instance_of?, true) do
        assert_calls(IRB, :start) do
          enter "irb"
          debug_code(minimal_program)
        end
      end
    end

    def test_autoirb_calls_irb_automatically_after_every_stop
      interface.stub(:instance_of?, true) do
        assert_calls(IRB, :start) do
          enter "set autoirb", "cont 5", "set noautoirb"
          debug_code(program)
        end
      end
    end
  end
end
