#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path('../../lib', __FILE__)
$LOAD_PATH << File.expand_path('../../test', __FILE__)

require 'minitest'

#
# Helper class to aid running minitest
#
class MinitestRunner
  def initialize
    @test_suites = extract_from_argv { |cmd_arg| test_suite?(cmd_arg) }
  end

  def run
    test_suites.each { |f| require File.expand_path(f) }

    Minitest.run(["--name=/#{tests.join('|')}/"])
  end

  private

  def runnables
    Minitest::Runnable.runnables
  end

  def runnable_classes
    @runnable_classes ||= runnables.map(&:to_s)
  end

  def test_suite?(str)
    all_test_suites.include?(str)
  end

  def test_suites
    return all_test_suites if @test_suites.empty?

    @test_suites
  end

  def test_class?(str)
    runnable_classes.include?(str)
  end

  def test_classes
    @test_classes ||= extract_from_argv { |cmd_arg| test_class?(cmd_arg) }
  end

  def test_method?(str)
    return false unless str =~ /^test_/

    runnables.each do |runnable|
      return true if runnable.runnable_methods.include?(str)
    end

    false
  end

  def test_methods
    @test_methods ||= extract_from_argv { |cmd_arg| test_method?(cmd_arg) }
  end

  def all_test_suites
    Dir.glob('test/**/*_test.rb')
  end

  def tests
    runnables.flat_map { |runnable| filter(runnable) }
  end

  def filter(test_class)
    return test_class if globally_filtered?(test_class)

    filtered_methods(test_class).map do |test_method|
      "#{test_class}##{test_method}"
    end
  end

  def globally_filtered?(test_class)
    test_classes.include?(test_class.to_s) && !filtered_methods?(test_class)
  end

  def filtered_methods?(test_class)
    filtered_methods(test_class).any?
  end

  def filtered_methods(test_class)
    test_class.runnable_methods & test_methods
  end

  def extract_from_argv
    matching, non_matching = ARGV.partition { |arg| yield(arg) }

    ARGV.replace(non_matching)

    matching
  end
end

MinitestRunner.new.run if $PROGRAM_NAME == __FILE__
