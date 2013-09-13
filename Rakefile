require 'rake/testtask'
require 'rake/extensiontask'
require 'bundler/gem_tasks'

Rake::ExtensionTask.new('byebug')

SO_NAME = "byebug.so"

desc "Run MiniTest suite"
task :test do
  Rake::TestTask.new(:test) do |t|
    t.test_files = FileList["test/*_test.rb"]
    t.warning = true
    t.verbose = true
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
