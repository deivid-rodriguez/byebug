# frozen_string_literal: true

require "support/assertions"

module Byebug
  #
  # Some custom matches for byebug's output
  #
  module TestMatchers
    def assert_output_includes(*args)
      assert_stream(:assert_includes_in_order, interface.output, *args)
    end

    def assert_error_includes(*args)
      assert_stream(:assert_includes_in_order, interface.error, *args)
    end

    def assert_output_doesnt_include(*args)
      assert_stream(:refute_includes_in_order, interface.output, *args)
    end

    def assert_error_doesnt_include(*args)
      assert_stream(:refute_includes_in_order, interface.error, *args)
    end

    private

    def assert_stream(check_method, stream, *args)
      send(check_method, Array(args), stream.map(&:strip))
    end
  end
end
