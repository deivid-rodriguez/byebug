#
# Starts code coverage tracking. If running on CI, use codeclimate's wrapper to
# report results to them.
#
def start_coverage_tracking
  require 'simplecov'
  SimpleCov.add_filter 'test'
  SimpleCov.start
end

start_coverage_tracking if ENV['NOCOV'].nil?
