#
# For the `release` task
#
require 'bundler/gem_tasks'

#
# For the `compile` task
#
require 'rake/extensiontask'

spec = Gem::Specification.load('byebug.gemspec')
Rake::ExtensionTask.new('byebug', spec) { |ext| ext.lib_dir = 'lib/byebug' }

#
# Prepend DevKit into compilation phase
#
desc 'Activates DevKit'
task :devkit do
  begin
    require 'devkit'
  rescue LoadError
    abort "Failed to activate RubyInstaller's DevKit required for compilation."
  end
end

task compile: :devkit if RUBY_PLATFORM =~ /mingw/

#
# Test task
#
desc 'Runs the test suite'
task :test do
  require_relative 'script/minitest_runner'

  MinitestRunner.new.run
end

desc 'Run overcommit hooks manually'
task(:overcommit) do
  system('bundle exec overcommit --run')
end

default_tasks = %i(compile test overcommit)

task default: default_tasks
task complete: [:clobber] + default_tasks

#
# Custom tasks for development
#
require_relative 'tasks/dev_utils.rb'
