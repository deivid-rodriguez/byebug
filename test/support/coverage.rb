#
# Starts code coverage tracking. If running on CI, use codeclimate's wrapper to
# report results to them.
#
def start_coverage_tracking
  if ENV['CI']
    require 'codeclimate-test-reporter'
    CodeClimate::TestReporter.start
  else
    require 'simplecov'
    SimpleCov.start
  end
end

#
# TODO: My guess is some bug fix in MRI's Coverage module was not backported to
# 2.0. Investigate this.
#
start_coverage_tracking if ENV['COV'] || (ENV['CI'] && RUBY_VERSION > '2.0.0')
