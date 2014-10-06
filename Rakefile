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

# prepend DevKit into compilation phase
if RUBY_PLATFORM =~ /mingw/
 task compile: :devkit
 task native: :devkit
end

desc 'Activates DevKit'
task :devkit do
  begin
    require 'devkit'
  rescue LoadError => e
    abort "Failed to activate RubyInstaller's DevKit required for compilation."
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

task default: [:clean, :compile, :test]
