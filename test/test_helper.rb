# frozen_string_literal: true

if ENV["NOCOV"].nil?
  require "simplecov"

  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  SimpleCov.start do
    add_filter "test"
  end
end

require "support/test_case"

Byebug::TestCase.before_suite
