require 'rake/testtask'
require 'rake/extensiontask'
require 'bundler/gem_tasks'

Rake::ExtensionTask.new('byebug') do |ext|
  ext.lib_dir = 'lib/byebug'
end

# Override default rake tests loader
class Rake::TestTask
  def rake_loader
    'test/test_helper.rb'
  end
end

desc "Run MiniTest suite"
task :test do
  Rake::TestTask.new do |t|
    t.verbose = true
    t.warning = true
    t.pattern = 'test/*_test.rb'
  end
end

base_spec = eval(File.read('byebug.gemspec'), binding, 'byebug.gemspec')

task :default => :test

desc 'Run a test in looped mode so that you can look for memory leaks'
task 'test_loop' do
  code = %Q[loop{ require '#{$*[1]}' }]
  cmd = %Q[ruby -Itest -e "#{ code }"]
  system cmd
end

desc 'Watch memory use of a looping test'
task 'test_loop_mem' do
  system "watch \"ps aux | grep -v 'sh -c r' | grep [I]test\""
end
