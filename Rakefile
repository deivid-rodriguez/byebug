#
# For the `rake release` task
#
require 'bundler/gem_tasks'

#
# Prepend DevKit into compilation phase
#
task compile: :devkit if RUBY_PLATFORM =~ /mingw/

require 'rake/extensiontask'

spec = Gem::Specification.load('byebug.gemspec')
Rake::ExtensionTask.new('byebug', spec) { |ext| ext.lib_dir = 'lib/byebug' }

desc 'Activates DevKit'
task :devkit do
  begin
    require 'devkit'
  rescue LoadError
    abort "Failed to activate RubyInstaller's DevKit required for compilation."
  end
end

#
# Custom tasks for development
#
require_relative 'tasks/dev_utils.rb'

#
# Test task
#
desc 'Runs the test suite'
task :test do
  require_relative 'script/minitest_runner'

  MinitestRunner.new.run
end

default_tasks = %i(compile test)

task default: default_tasks
task complete: [:clobber] + default_tasks
