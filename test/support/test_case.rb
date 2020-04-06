# frozen_string_literal: true

ENV["MT_NO_PLUGINS"] = "yes, no plugins"
require "minitest"

require "byebug"
require "byebug/core"
require "byebug/interfaces/test_interface"
require_relative "utils"

module Byebug
  #
  # Extends Minitest's base test case and provides defaults for all tests.
  #
  class TestCase < Minitest::Test
    make_my_diffs_pretty!

    include TestUtils
    include Helpers::StringHelper

    def self.before_suite
      Byebug.init_file = ".byebug_test_rc"

      Context.interface = TestInterface.new
      Context.ignored_files = Context.all_files
    end

    #
    # Reset to default state before each test
    #
    def setup
      Byebug.start
      interface.clear
    end

    #
    # Cleanup temp files, and dummy classes/modules.
    #
    def teardown
      cleanup_namespace
      clear_example_file

      Byebug.breakpoints&.clear
      Byebug.catchpoints&.clear

      Byebug.stop
    end

    #
    # Removes test example file and its memoization
    #
    def clear_example_file
      example_file.close

      delete_example_file

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
      @example_file ||= File.new(example_path, "w+")
    end

    #
    # Path to file where test code is saved
    #
    def example_path
      File.join(example_folder, "byebug_example.rb")
    end

    #
    # Fully namespaced example class
    #
    def example_full_class
      "Byebug::#{example_class}"
    end

    #
    # Name of the temporary test class
    #
    def example_class
      "#{camelized_path}Class"
    end

    #
    # Name of the temporary test module
    #
    def example_module
      "#{camelized_path}Module"
    end

    #
    # Temporary folder where the test file lives
    #
    def example_folder
      @example_folder ||= File.realpath(Dir.tmpdir)
    end

    private

    def camelized_path
      camelize(File.basename(example_path, ".rb"))
    end

    def delete_example_file
      File.unlink(example_file)
    rescue StandardError
      # On windows we need the file closed before deleting it, and sometimes it
      # didn't have time to close yet. So retry until we can delete it.
      retry
    end
  end
end
