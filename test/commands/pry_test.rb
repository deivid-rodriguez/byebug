require 'mocha/mini_test'
require 'test_helper'

module Byebug
  #
  # Tests entering Pry from within Byebug.
  #
  class PryTest < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    byebug
        3:
        4:    a = 2
        5:    a + 4
        6:  end
      EOC
    end

    def setup
      super

      interface.stubs(:kind_of?).with(LocalInterface).returns(true)
    end

    def test_pry_command_starts_a_pry_session_if_pry_installed
      PryCommand.any_instance.expects(:execute)

      enter 'pry'
      debug_code(minimal_program)
    end

    def test_autopry_calls_pry_automatically_after_every_stop
      PryCommand.any_instance.expects(:execute)

      enter 'set autopry', 'cont 5', 'set noautopry'
      debug_code(program)
    end
  end
end
