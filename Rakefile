# frozen_string_literal: true

import "tasks/compile.rake"
import "tasks/test.rake"
import "tasks/coverage.rake"
import "tasks/release.rake"
import "tasks/docs.rake"
import "tasks/lint.rake"
import "tasks/docker.rake"

if Gem.win_platform?
  task default: %i[compile test]
else
  task default: %i[compile test lint]
end
