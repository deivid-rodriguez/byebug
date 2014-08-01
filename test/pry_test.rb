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
        a = 5
        a = 6
      end

      super

      interface.stubs(:kind_of?).with(LocalInterface).returns(true)
      PryCommand.any_instance.expects(:pry)
    end

    def test_pry_supports_next_command
      skip 'TODO'
    end

    def test_pry_supports_step_command
      skip 'TODO'
    end

    def test_pry_supports_cont_command
      skip 'TODO'
    end

    def test_autopry_calls_pry_automatically_after_every_stop
      skip 'TODO'
    end
  end
end if has_pry
