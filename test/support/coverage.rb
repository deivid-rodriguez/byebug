#
# Starts code coverage tracking.
#
def start_coverage_tracking
  require 'simplecov'
  SimpleCov.add_filter '.bundle'
  SimpleCov.start
end

start_coverage_tracking if ENV['NOCOV'].nil?
