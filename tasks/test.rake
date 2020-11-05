# frozen_string_literal: true

desc "Runs the test suite"
task :test do
  require_relative "../test/minitest_runner"

  exit 1 unless Byebug::MinitestRunner.new.run
end
