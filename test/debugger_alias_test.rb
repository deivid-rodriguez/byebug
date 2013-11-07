require_relative 'test_helper'

class TestDebuggerAlias < MiniTest::Spec
  it 'aliases "debugger" to "byebug"' do
    Kernel.method(:debugger).must_equal(Kernel.method(:byebug))
  end
end
