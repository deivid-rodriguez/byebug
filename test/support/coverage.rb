#
# Starts coverage tracking unless using Ruby 2.0, because it gives a wrong
# result in this version. If running on CI, use codeclimate's wrapper to report
# results to them.
#
# TODO: My guess is some bug fix in MRI's Coverage module was not backported to
# 2.0. Investigate this.
#
def start_coverage_tracking
  return if RUBY_VERSION < '2.1'

  if ENV['CI']
    require 'codeclimate-test-reporter'
    CodeClimate::TestReporter.start
  else
    require 'simplecov'
    SimpleCov.start
  end
end

start_coverage_tracking
