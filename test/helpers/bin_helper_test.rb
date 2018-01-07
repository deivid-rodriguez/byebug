# frozen_string_literal: true

require "test_helper"

module Byebug
  module Helpers
    class BinHelperTest < Minitest::Test
      include BinHelper

      def test_which_resolves_ruby
        assert_equal true, File.exist?(which("ruby"))
      end
    end
  end
end
