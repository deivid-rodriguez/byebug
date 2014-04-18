module TimeoutTest
  class TimeoutTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
      end
    end

    it 'must evaluate expression that calls Timeout::timeout' do
      enter 'eval Timeout::timeout(60) { 1 }'
      debug_proc(@example)
      check_output_includes '1'
    end
  end
end
