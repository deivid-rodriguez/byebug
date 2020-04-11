# frozen_string_literal: true

require "simplecov" if ENV["NOCOV"].nil? && Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.6.a")
require "support/test_case"

Byebug::TestCase.before_suite
