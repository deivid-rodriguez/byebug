require 'rake/testtask'
require 'rake/extensiontask'
require 'bundler/gem_tasks'

Rake::ExtensionTask.new('byebug')

SO_NAME = "byebug.so"

desc "Run MiniTest suite"
task :test do
  Rake::TestTask.new(:test) do |t|
    t.test_files = FileList["test/*_test.rb"]
    t.verbose = true
  end
end

base_spec = eval(File.read('byebug.gemspec'), binding, 'byebug.gemspec')

task :default => :test
