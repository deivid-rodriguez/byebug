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
  task all: %i[clang_format executables tabs trailing_whitespace rubocop mdl]

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

  desc "Check for trailing whitespace"
  task :trailing_whitespace do
    puts "Checking for unnecessary trailing whitespace"

    TrailingWhitespaceLinter.new.run
  end

  require "rubocop/rake_task"

  desc "Checks ruby code style with RuboCop"
  RuboCop::RakeTask.new

  desc "Checks markdown code style with Markdownlint"
  task :mdl do
    puts "Running mdl"

    abort unless system("mdl", *Dir.glob("*.md"))
  end

  desc "Checks shell code style with shellcheck"
  task :shellcheck do
    puts "Running shellcheck"

    abort unless system("shellcheck", *Dir.glob("bin/*.sh"))
  end
end

desc "Runs lint tasks"
task lint: "lint:all"

namespace :docker do
  require_relative "docker/manager"

  desc "Build all docker images"
  task :build_all do
    Docker::Manager.build_all
  end

  desc "Build the default docker image"
  task :build do
    Docker::Manager.build_default
  end

  desc "Build a ruby trunk image"
  task :build_and_push_head, %i[line_editor compiler] do |_t, opts|
    manager = Docker::Manager.new(
      version: "head",
      line_editor: opts[:line_editor],
      compiler: opts[:compiler]
    )

    manager.build && manager.push
  end

  desc "Test all docker images"
  task :test_all do
    Docker::Manager.test_all
  end

  desc "Test the default docker image"
  task :test do
    Docker::Manager.test_default
  end

  desc "Push all docker images to dockerhub"
  task :push_all do
    Docker::Manager.push_all
  end

  desc "Push the default docker image to dockerhub"
  task :push do
    Docker::Manager.push_default
  end
end

task default: %i[compile test lint]

YARD::Rake::YardocTask.new
