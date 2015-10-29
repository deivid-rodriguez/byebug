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

#
# Coverage tracking is incorrect in 2.0
#
start_coverage_tracking if RUBY_VERSION > '2.0.0'
