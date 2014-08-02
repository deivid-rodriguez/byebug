if ENV['CI']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'minitest'
require 'pathname'
require 'mocha/mini_test'
require 'byebug'

require_relative 'support/utils'

class Byebug::TestCase < Minitest::Test
  #
  # Reset to default state before each test
  #
  def setup
    Byebug.handler = Byebug::CommandProcessor.new(Byebug::TestInterface.new)
    Byebug.breakpoints.clear if Byebug.breakpoints
    Byebug.catchpoints.clear if Byebug.catchpoints

    Byebug::Setting.load
    Byebug::Setting[:autolist] = false
    Byebug::Setting[:testing] = true
    Byebug::Setting[:verbose] = true
    Byebug::Setting[:width] = 80

    byebug_bin = File.expand_path('../../../bin/byebug', __FILE__)
    force_set_const(Byebug, 'BYEBUG_SCRIPT', byebug_bin)
    force_set_const(Byebug, 'PROG_SCRIPT', $0)
  end

  include Byebug::TestUtils
end

# Init globals to avoid warnings
$bla = nil
$binding = binding # this is from irb...

# Load the test files from the command line.
argv = ARGV.select do |argument|
  case argument
  when /^-/ then
    argument
  when /\*/ then
    Dir.glob('test/*_test.rb').each do |file|
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
