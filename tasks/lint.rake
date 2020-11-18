# frozen_string_literal: true

namespace :lint do
  desc "Install lint tools"
  task :install do
    if RUBY_VERSION >= "2.6"
      Bundler.original_system({ "BUNDLE_GEMFILE" => "gemfiles/lint/Gemfile" }, "bundle", "install", exception: true)
    else
      abort unless Bundler.original_system({ "BUNDLE_GEMFILE" => "gemfiles/lint/Gemfile" }, "bundle", "install")
    end
  end

  desc "Run all linters"
  task all: %i[clang_format executables tabs trailing_whitespace rubocop mdl]

  require_relative "linter"

  desc "Run clang_format on C files"
  task :clang_format do
    if Gem.win_platform?
      puts "Skipping C file linting on Windows since clang-format is not available"
    else
      puts "Running linter on C files"

      CLangFormatLinter.new.run
    end
  end

  desc "Check unnecessary execute permissions"
  task :executables do
    if Gem.win_platform?
      puts "Skipping check for exectuables on Windows since it does not support execute permissions separately from read permissions"
    else
      puts "Checking for unnecessary executables"

      ExecutableLinter.new.run
    end
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

  desc "Checks ruby code style with RuboCop"
  task :rubocop do
    puts "Running rubocop"

    if RUBY_VERSION >= "2.6"
      Bundler.original_system("bin/rubocop", exception: true)
    else
      abort unless Bundler.original_system("bin/rubocop")
    end
  end

  desc "Checks markdown code style with Markdownlint"
  task :mdl do
    puts "Running mdl"

    if RUBY_VERSION >= "2.6"
      Bundler.original_system("bin/mdl", *Dir.glob("*.md"), exception: true)
    else
      abort unless Bundler.original_system("bin/mdl")
    end
  end

  desc "Checks shell code style with shellcheck"
  task :shellcheck do
    puts "Running shellcheck"

    sh("shellcheck", *Dir.glob("bin/*.sh"))
  end
end

desc "Runs lint tasks"
task lint: ["lint:install", "lint:all"]
