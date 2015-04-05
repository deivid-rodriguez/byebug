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

desc 'Run the test suite'
task :test do
  files = Dir.glob('test/**/*_test.rb').join(' ')
  system("ruby -w -Ilib test/test_helper.rb #{files}") || exit(false)
end

desc 'Activates DevKit'
task :devkit do
  begin
    require 'devkit'
  rescue LoadError
    abort "Failed to activate RubyInstaller's DevKit required for compilation."
  end
end

require 'rubocop/rake_task'

desc 'Run RuboCop'
task(:rubocop) { RuboCop::RakeTask.new }

require_relative 'tasks/ccop.rb'
require_relative 'tasks/dev_utils.rb'

default_tasks = %i(compile test rubocop)
default_tasks << :ccop unless RUBY_PLATFORM =~ /darwin/

task default: default_tasks
