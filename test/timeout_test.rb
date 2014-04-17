class TestTimeout < TestDsl::TestCase
  it 'must evaluate expression that calls Timeout::timeout' do
    enter 'eval Timeout::timeout(60) { 1 }'
    debug_file 'timeout'
    check_output_includes '1'
  end
end
