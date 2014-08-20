require 'rake/testtask'
require 'rake/extensiontask'
require 'bundler/gem_tasks'

Rake::ExtensionTask.new('byebug') do |ext|
  ext.lib_dir = 'lib/byebug'
end

module Rake
  #
  # Overrides default rake tests loader
  #
  class TestTask
    def rake_loader
      'test/test_helper.rb'
    end
  end
end

desc 'Run the test suite'
task :test do
  Rake::TestTask.new do |t|
    t.verbose = true
    t.warning = true
    t.pattern = 'test/**/*_test.rb'
  end
end

task default: :test

desc 'Run a test in looped mode so that you can look for memory leaks'
task 'test_loop' do
  code = %(loop{ require '#{$ARGV[1]}' })
  cmd = %(ruby -Itest -e "#{ code }")
  system cmd
end

desc 'Watch memory use of a looping test'
task 'test_loop_mem' do
  system "watch \"ps aux | grep -v 'sh -c r' | grep [I]test\""
end
