require 'byebug/interfaces/test_interface'

module Byebug
  #
  # During tests, ignore rc files
  #
  def self.run_init_script
  end

  class Context
    class << self
      undef :ignored_files

      #
      # List of files to be ignored during a test run
      #
      def ignored_files
        @ignored_files ||=
          `git ls-files -z`.split("\x0").map { |f| File.expand_path(f) }
      end
    end
  end

  #
  # Extends Minitest's base test case and provides defaults for all tests.
  #
  class TestCase < Minitest::Test
    self.make_my_diffs_pretty!

    include Byebug::TestUtils

    #
    # Stuff to be run once before the test suite
    #
    def self.before_suite
      Byebug.handler = Byebug::CommandProcessor.new(Byebug::TestInterface.new)
    end

    #
    # Reset to default state before each test
    #
    def setup
      interface.clear
      Byebug.breakpoints.clear if Byebug.breakpoints
    end

    #
    # Cleanup temp files, and dummy classes/modules.
    #
    def teardown
      cleanup_namespace
      clear_example_file
      Byebug.stop
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
