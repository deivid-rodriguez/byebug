# frozen_string_literal: true

namespace :docker do
  require_relative "../docker/manager"

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

    manager.build
    manager.login
    manager.push
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
