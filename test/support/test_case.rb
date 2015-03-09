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
      Byebug::Context.stubs(:ignored_files).returns(ignored_files)

      set_defaults
    end

    #
    # Cleanup temp files, and dummy classes/modules.
    #
    def teardown
      cleanup_namespace
      clear_example_file
    end

    #
    # List of files to be ignored during a test run
    #
    def ignored_files
      return @ignored_files if defined?(@ignored_files)

      pattern = File.expand_path('../../../{lib,test}/**/*.rb', __FILE__)
      @ignored_files = Dir.glob(pattern) - [example_path]
    end

    #
    # Removes test example file and its memoization
    #
    def clear_example_file
      example_file.unlink

      @example_file = nil
    end

    #
    # Cleanup main Byebug namespace from dummy test classes and modules
    #
    def cleanup_namespace
      force_remove_const(Byebug, example_class)
      force_remove_const(Byebug, example_module)
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
      File.realpath(example_file.path)
    end

    #
    # Name of the temporary test class.
    #
    def example_class
      "#{camelized_path}Class"
    end

    #
    # Name of the temporary test module.
    #
    def example_module
      "#{camelized_path}Module"
    end

    private

    include StringFunctions

    def camelized_path
      camelize(File.basename(example_path, '.rb'))
    end
  end
end
