# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path(File.join("..", "lib"), __dir__))
$LOAD_PATH.unshift(__dir__)

require "minitest"
require "English"
require "shellwords"
require "timeout"

module Byebug
  #
  # Helper class to aid running minitest
  #
  class MinitestRunner
    def initialize
      @test_suites = extract_from_argv { |cmd_arg| test_suite?(cmd_arg) }
    end

    def run
      test_suites.each { |f| require File.expand_path(f) }

      flags = ["--name=/#{filtered_methods.join('|')}/"]

      run_with_timeout(flags)
    end

    private

    def max_running_time
      300
    end

    def run_with_timeout(flags)
      Timeout.timeout(max_running_time) { Minitest.run(flags + $ARGV) }
    rescue Timeout::Error
      warn "Test suite timed out after #{max_running_time} seconds"
      false
    end

    def runnables
      Minitest::Runnable.runnables
    end

    def test_suite?(str)
      all_test_suites.include?(str)
    end

    def test_suites
      return all_test_suites if @test_suites.empty?

      @test_suites
    end

    def test_methods(str)
      if /test_.*/.match?(str)
        filter_runnables_by_method(str)
      else
        filter_runnables_by_class(str)
      end
    end

    def filter_runnables_by_method(str)
      filter_runnables do |runnable|
        "#{runnable}##{str}" if runnable.runnable_methods.include?(str)
      end
    end

    def filter_runnables_by_class(str)
      filter_runnables do |runnable|
        runnable.runnable_methods if runnable.name == "Byebug::#{str}"
      end
    end

    def filter_runnables
      selected = runnables.flat_map do |runnable|
        yield(runnable)
      end.compact

      return unless selected.any?

      selected
    end

    def filtered_methods
      @filtered_methods ||= extract_from_argv do |cmd_arg|
        test_methods(cmd_arg)
      end
    end

    def all_test_suites
      Dir.glob("test/**/*_test.rb")
    end

    def extract_from_argv
      matching, non_matching = $ARGV.partition { |arg| yield(arg) }

      $ARGV.replace(non_matching)

      matching
    end
  end
end
