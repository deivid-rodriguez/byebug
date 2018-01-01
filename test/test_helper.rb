# frozen_string_literal: true

require "simplecov" if ENV["NOCOV"].nil?
require "support/test_case"

Byebug::TestCase.before_suite
