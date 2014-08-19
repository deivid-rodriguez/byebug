begin
  require 'pry'
  has_pry = true
rescue LoadError
  has_pry = false
end

module Byebug
  class PryTestCase < TestCase
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

    def test_pry_command_starts_a_pry_session
      PryCommand.any_instance.expects(:execute)
      enter 'pry'
      debug_proc(@example)
    end

    def test_autopry_calls_pry_automatically_after_every_stop
      skip 'TODO'
    end
  end
end if has_pry
