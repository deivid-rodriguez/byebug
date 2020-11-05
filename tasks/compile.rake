# frozen_string_literal: true

require "rake/extensiontask"

spec = Gem::Specification.load("byebug.gemspec")
Rake::ExtensionTask.new("byebug", spec) { |ext| ext.lib_dir = "lib/byebug" }
