module Byebug
  class DebuggerAliasTestCase < Minitest::Test
    def test_aliases_debugger_to_byebug
      assert_equal Kernel.method(:byebug), Kernel.method(:debugger)
    end
  end
end
