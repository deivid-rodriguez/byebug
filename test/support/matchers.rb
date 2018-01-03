# frozen_string_literal: true

require "support/assertions"

module Byebug
  #
  # Some custom matches for byebug's output
  #
  module TestMatchers
    def check_output_includes(*args)
      check_stream(:assert_includes_in_order, interface.output, *args)
    end

    def check_error_includes(*args)
      check_stream(:assert_includes_in_order, interface.error, *args)
    end

    def check_output_doesnt_include(*args)
      check_stream(:refute_includes_in_order, interface.output, *args)
    end

    def check_error_doesnt_include(*args)
      check_stream(:refute_includes_in_order, interface.error, *args)
    end

    private

    def check_stream(check_method, stream, *args)
      send(check_method, Array(args), stream.map(&:strip))
    end
  end
end
