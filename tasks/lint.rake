# frozen_string_literal: true

namespace :lint do
  desc "Run all linters"
  task all: %i[clang_format executables tabs trailing_whitespace rubocop mdl]

  require_relative "linter"

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

    sh("bin/mdl", *Dir.glob("*.md"))
  end

  desc "Checks shell code style with shellcheck"
  task :shellcheck do
    puts "Running shellcheck"

    sh("shellcheck", *Dir.glob("bin/*.sh"))
  end
end

desc "Runs lint tasks"
task lint: "lint:all"
