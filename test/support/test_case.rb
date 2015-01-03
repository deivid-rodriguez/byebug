require 'byebug/interfaces/test_interface'

module Byebug
  #
  # Extends Minitest's base test case and provides defaults for all tests.
  #
  class TestCase < Minitest::Test
    self.make_my_diffs_pretty!

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
    # Cleanup temp file holding the test and (possibly) the test class
    #
    def teardown
      force_remove_const(Byebug, example_class)
      clear_example_file
    end

    #
    # List of files to be ignored during a test run
    #
    def ignored_files
      pattern = File.expand_path('../../../{lib,test}/**/*.rb', __FILE__)
      Dir.glob(pattern) - [example_path]
    end

    def clear_example_file
      example_file.unlink

      @example_file = nil
    end

    #
    # Temporary file where code for each test is saved
    #
    def example_file
      @example_file ||= Tempfile.new(['byebug_test', '.rb'])

      @example_file.open if @example_file.closed?

      @example_file
    end

    #
    # Path to file where test code is saved
    #
    def example_path
      example_file.path
    end

    include StringFunctions
    #
    # Name of the temporary test class.
    #
    def example_class
      camelize(File.basename(example_path, '.rb'))
    end
  end
end
