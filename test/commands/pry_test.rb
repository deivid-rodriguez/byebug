# frozen_string_literal: true

require "pry"
require "test_helper"
require "minitest/mock"

module Byebug
  #
  # Tests entering Pry from within Byebug.
  #
  class PryTest < TestCase
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

    def test_pry_command_starts_a_pry_session_if_pry_installed
      interface.stub(:instance_of?, true) do
        assert_calls(Pry, :start) do
          enter "pry"
          debug_code(minimal_program)
        end
      end
    end

    def test_autopry_calls_pry_automatically_after_every_stop
      interface.stub(:instance_of?, true) do
        assert_calls(Pry, :start) do
          enter "set autopry", "cont 5", "set noautopry"
          debug_code(program)
        end
      end
    end
  end
end
