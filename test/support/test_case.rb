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
      Byebug.stubs(:run_init_script)

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

    #
    # Temporary file created during a test run to store a test program.
    #
    def example_path
      'test/current_example.rb'
    end

    #
    # Full path to example_path.
    #
    def example_fullpath
      File.expand_path(example_path)
    end

    #
    # Name of the temporary test class.
    #
    def example_class
      'TestExample'
    end
  end
end
