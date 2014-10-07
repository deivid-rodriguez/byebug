if ENV['CI']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
else
  require 'simplecov'
  SimpleCov.start
end

require 'minitest'
require 'mocha/mini_test'

require 'byebug'

require_relative 'support/utils'
require_relative 'support/test_case'

# Load the test files from the command line.
argv = ARGV.select do |argument|
  case argument
  when /^-/ then
    argument
  when /\*/ then
    Dir.glob('test/**/*_test.rb').each do |file|
      require File.expand_path file
    end
    false
  else
    require File.expand_path argument
    false
  end
end

# Run the tests
Minitest.run argv
