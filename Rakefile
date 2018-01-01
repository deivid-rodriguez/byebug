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
  require_relative "bin/minitest"

  exit 1 unless MinitestRunner.new.run
end

namespace :lint do
  require_relative "tasks/linter"

  desc "Run clang_format on C files"
  task :clang_format do
    puts "Running linter on C files"

    CLangFormatLinter.new.run
  end

  desc "Check unnecessary execute permissions"
  task :unnecessary_executables do
    puts "Checking for unnecessary executables"

    ExecutableLinter.new.run
  end
end

desc "Runs lint tasks not available on codeclimate"
task lint: ["lint:clang_format", "lint:unnecessary_executables"]

desc "Build docker images"
task :build_docker_images do
  require_relative "docker/manager"

  Docker::Manager.build_all
end

desc "Push docker images to dockerhub"
task :push_docker_images do
  require_relative "docker/manager"

  Docker::Manager.push_all
end

task default: %i[compile test lint]

YARD::Rake::YardocTask.new
