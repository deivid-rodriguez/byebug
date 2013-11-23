class ContinueExample
  def self.a(num)
    num + 4
  end
end

class TestContinue < TestDsl::TestCase

  describe "successful" do
    it "must continue up to breakpoint if no line specified" do
      enter 'break 4', 'continue'
      debug_file('continue') { state.line.must_equal 4 }
    end

    it "must work in abbreviated mode too" do
      enter 'break 4', 'cont'
      debug_file('continue') { state.line.must_equal 4 }
    end

    it "must continue up to specified line" do
      enter 'cont 4'
      debug_file('continue') { state.line.must_equal 4 }
    end
  end

  describe "unsuccessful" do
    it "must ignore the command if specified line is not valid" do
      enter 'cont 123'
      debug_file('continue') { state.line.must_equal 3 }
    end

    it "must show error if specified line is not valid" do
      enter 'cont 123'
      debug_file 'continue'
      check_error_includes \
        "Line 123 is not a stopping point in file \"#{fullpath('continue')}\""
    end
  end
end
