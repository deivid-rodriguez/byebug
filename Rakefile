# frozen_string_literal: true

require "bundler/gem_tasks"
require "chandler/tasks"
require "rake/extensiontask"
require "yard"

#
# Add chandler as a prerequisite for `rake release`
#
task "release:rubygem_push" => "chandler:push"

#
# Prepend DevKit into compilation phase
#
if Gem.win_platform?
  desc "Activates DevKit"
  task :devkit do
    begin
      require "devkit"
    rescue LoadError
      abort "Failed to load DevKit required for compilation"
    end
  end

  task compile: :devkit
end

spec = Gem::Specification.load("byebug.gemspec")
Rake::ExtensionTask.new("byebug", spec) { |ext| ext.lib_dir = "lib/byebug" }

desc "Runs the test suite"
task :test do
  require_relative "test/minitest_runner"

  exit 1 unless Byebug::MinitestRunner.new.run
end

namespace :lint do
  desc "Run all linters"
  task all: %i[clang_format executables tabs rubocop mdl]

  require_relative "tasks/linter"

  desc "Run clang_format on C files"
  task :clang_format do
    puts "Running linter on C files"

    CLangFormatLinter.new.run
  end

  desc "Check unnecessary execute permissions"
  task :executables do
    puts "Checking for unnecessary executables"

    ExecutableLinter.new.run
  end

  desc "Check for tabs"
  task :tabs do
    puts "Checking for unnecessary tabs"

    TabLinter.new.run
  end

  require "rubocop/rake_task"

  RuboCop::RakeTask.new

  desc "Checks markdown code style with Markdownlint"
  task :mdl do
    puts "Running mdl..."

    abort unless system("mdl", *Dir.glob("*.md"))
  end
end

desc "Runs lint tasks not available on codeclimate"
task lint: "lint:all"

namespace :docker do
  require_relative "docker/manager"

  desc "Build docker images"
  task :build do
    Docker::Manager.build_all
  end

  desc "Test docker images"
  task :test do
    Docker::Manager.test_all
  end

  desc "Push docker images to dockerhub"
  task :push do
    Docker::Manager.push_all
  end
end

task default: %i[compile test lint]

YARD::Rake::YardocTask.new
