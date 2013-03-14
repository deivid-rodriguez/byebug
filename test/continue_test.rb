require_relative 'test_helper'

describe "Continue Command" do
  include TestDsl

  it "must continue up to breakpoint" do
    enter 'break 4', 'continue'
    debug_file('continue') { state.line.must_equal 4 }
  end

  it "must continue up to specified line" do
    enter 'cont 4'
    debug_file('continue') { state.line.must_equal 4 }
  end

  it "must ignore the command if there is no specified line" do
    enter 'cont 123'
    debug_file('continue') { state.line.must_equal 2 }
  end

  it "must show error if there is no specified line" do
    enter 'cont 123'
    debug_file('continue')
    check_output_includes "Line 123 is not a stopping point in file \"#{fullpath('continue')}\".", interface.error_queue
  end

  it "must ignore the line if the context is dead"
end
