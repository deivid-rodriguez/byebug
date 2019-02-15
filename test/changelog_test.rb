# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests sanity of changelog file.
  #
  class ChangelogTest < Minitest::Test
    def test_has_definitions_for_all_releases
      changelog.scan(/\[([0-9]+\.[0-9]+\.[0-9]+)\] /).flatten.uniq.each do |release_version|
        assert_match %r{^\[#{release_version}\]: https://github\.com/deivid-rodriguez/byebug/compare/v[0-9]+\.[0-9]+\.[0-9]+...v#{release_version}}, changelog
      end
    end

    private

    def changelog
      File.read("CHANGELOG.md")
    end
  end
end
