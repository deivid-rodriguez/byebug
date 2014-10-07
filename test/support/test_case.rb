require 'byebug/interfaces/test_interface'

module Byebug
  #
  # Extends Minitest's base test case and provides defaults for all tests.
  #
  class TestCase < Minitest::Test
    include Byebug::TestUtils

    #
    # Reset to default state before each test
    #
    def setup
      Byebug.handler = Byebug::CommandProcessor.new(Byebug::TestInterface.new)
      Byebug.breakpoints.clear if Byebug.breakpoints
      Byebug.catchpoints.clear if Byebug.catchpoints

      set_defaults

      force_set_const(Byebug, 'IGNORED_FILES', ignored_files)
    end

    #
    # List of files to be ignored during a test run.
    #
    def ignored_files
      list = File.expand_path('../../../{lib,test/support}/**/*.rb', __FILE__)
      Dir.glob(list) + ['test/test_helper.rb']
    end
  end
end
