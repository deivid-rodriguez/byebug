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
    # Cleanup after each test
    #
    def teardown
      example_file.unlink
    end

    #
    # List of files to be ignored during a test run.
    #
    def ignored_files
      pattern = File.expand_path('../../../{lib,test}/**/*.rb', __FILE__)
      Dir.glob(pattern) - [example_path]
    end

    #
    # File where test code is saved
    #
    def example_file
      @example_file ||= Tempfile.new(['byebug_test', '.rb'])
    end

    #
    # Path to file where test code is saved
    #
    def example_path
      example_file.path
    end

    #
    # Full path to file where test code is saved
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
