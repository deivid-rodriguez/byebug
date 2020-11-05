# frozen_string_literal: true

namespace :coverage do
  desc "Merges all result sets into a single coverage report"
  task :collate do
    ENV["COV_COLLATION"] = "true"

    require "simplecov"

    SimpleCov.collate Dir["coverage/*.json"]
  end
end
