# frozen_string_literal: true

require "bundler/gem_tasks"
require "chandler/tasks"

#
# Add chandler as a prerequisite for `rake release`
#
task "release:rubygem_push" => "chandler:push"
