#
# Starts code coverage tracking. If running on CI, use codeclimate's wrapper to
# report results to them.
#
def start_coverage_tracking
  require 'simplecov'
  SimpleCov.add_filter 'test'

  if ENV['CI']
    require 'codeclimate-test-reporter'
    CodeClimate::TestReporter.start
  else
    SimpleCov.start
  end
end

start_coverage_tracking if ENV['NOCOV'].nil?
