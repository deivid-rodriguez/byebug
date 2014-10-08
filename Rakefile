#
# Prepend DevKit into compilation phase
#
if RUBY_PLATFORM =~ /mingw/
  task compile: :devkit
  task native: :devkit
end

require 'rake/extensiontask'

spec = Gem::Specification.load('byebug.gemspec')
Rake::ExtensionTask.new('byebug', spec) do |ext|
  ext.lib_dir = 'lib/byebug'
end

require 'rake/testtask'

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

desc 'Activates DevKit'
task :devkit do
  begin
    require 'devkit'
  rescue LoadError
    abort "Failed to activate RubyInstaller's DevKit required for compilation."
  end
end

task default: [:native, :test]
