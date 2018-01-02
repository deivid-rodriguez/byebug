#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << File.expand_path(File.join("..", "lib"), __dir__)
$LOAD_PATH << File.expand_path(File.join("..", "test"), __dir__)

require "minitest"
require "English"
require "shellwords"

#
# Helper class to aid running minitest
#
class MinitestRunner
  def initialize
    @test_suites = extract_from_argv { |cmd_arg| test_suite?(cmd_arg) }
  end

  def run
    test_suites.each { |f| require File.expand_path(f) }

    flags = ["--name=/#{filtered_methods.join('|')}/", *test_opts]

    run_with_timeout(flags)
  end

  private

  def run_with_timeout(flags)
    Timeout.timeout(180) { Minitest.run(flags + $ARGV) }
  rescue Timeout::Error
    false
  end

  def runnables
    Minitest::Runnable.runnables
  end

  def test_suite?(str)
    all_test_suites.include?(str)
  end

  def test_opts
    return [] unless ENV["TESTOPTS"]

    ENV["TESTOPTS"].shellsplit
  end

  def test_suites
    return all_test_suites if @test_suites.empty?

    @test_suites
  end

  def test_methods(str)
    if str =~ /test_.*/
      normalize(str)
    elsif str =~ /.*#test_.*/
      [str]
    else
      expand(str)
    end
  end

  def normalize(str)
    runnables.each do |runnable|
      return "#{runnable}##{str}" if runnable.runnable_methods.include?(str)
    end
  end

  def expand(str)
    runnables.each do |runnable|
      return runnable.runnable_methods if str == "Byebug::#{runnable}"
    end
  end

  def filtered_methods
    @filtered_methods ||= extract_from_argv { |cmd_arg| test_methods(cmd_arg) }
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

exit(MinitestRunner.new.run) if $PROGRAM_NAME == __FILE__
