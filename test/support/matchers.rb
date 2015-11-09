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

module Minitest
  #
  # Custom Minitest assertions
  #
  module Assertions
    #
    # Checks that a given collection is included in another collection
    # and in correct order. It accepts both strings and regexps as elements of
    # the arrays.
    #
    # @param given [Array] Collection to be checked for inclusion.
    # @param original [Array] Collection +given+ is checked against.
    #
    # @example Passing assertion with simple array
    #   assert_includes_in_order(%w(1 2 3 4 5), %w(1 3 5))
    #
    # @example Failing assertion with simple array
    #   assert_includes_in_order(%w(1 2 3 4 5), %w(1 5 3))
    #
    # @example Passing assertion with array and regexp elements
    #   assert_includes_in_order(%w(1 2 3 4 5), ['1', /\d+/, '5'])
    #
    # @example Failing assertion with array and regexp elements
    #   assert_includes_in_order(%w(1 2 3 4 5), ['1', /\[a-z]+/, '5'])
    #
    def assert_includes_in_order(given, original, msg = nil)
      msg = message(msg) do
        "Expected #{mu_pp(original)} to include #{mu_pp(given)} in order"
      end
      assert _includes_in_order(given, original), msg
    end

    def refute_includes_in_order(given, original, msg = nil)
      msg = message(msg) do
        "Expected #{mu_pp(original)} to not include #{mu_pp(given)} in order"
      end
      refute _includes_in_order(given, original), msg
    end

    def assert_location(file, line)
      expected = "#{file}:#{line}"
      actual = "#{frame.file}:#{frame.line}"
      msg = "Expected location to be #{expected}, but was #{actual}"

      assert file == frame.file && line == frame.line, msg
    end

    def assert_program_finished
      assert_nil context.backtrace, 'Expected program to have finished'
    end

    private

    def _includes_in_order(collection, original_collection)
      collection.reduce(0) do |index, item|
        current_collection = original_collection[index..-1]

        i = case item
            when String then current_collection.index(item)
            when Regexp then current_collection.index { |it| it =~ item }
            end
        return false unless i

        i + 1
      end

      true
    end
  end
end
