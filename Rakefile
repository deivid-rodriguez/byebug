# frozen_string_literal: true

import "tasks/compile.rake"
import "tasks/test.rake"
import "tasks/coverage.rake"

gemfile = ENV["BUNDLE_GEMFILE"]

if gemfile.nil? || File.expand_path(gemfile) == File.expand_path("Gemfile")
  import "tasks/release.rake"
  import "tasks/docs.rake"
  import "tasks/lint.rake"
  import "tasks/docker.rake"

  task default: %i[compile test lint]
else
  task default: %i[compile test]
end
