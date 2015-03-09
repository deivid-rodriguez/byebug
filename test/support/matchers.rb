module Minitest
  #
  # Custom Minitest assertions
  #
  module Assertions
    # This matcher checks that given collection is included into the original
    # collection and in correct order. It accepts both strings and regexps.
    #
    # Examples:
    #   assert_includes_in_order(%w{1 2 3 4 5}, %w{1 3 5})            # => pass
    #   assert_includes_in_order(%w{1 2 3 4 5}, %w{1 5 3})            # => fail
    #   assert_includes_in_order(w{1 2 3 4 5}, ["1", /\d+/, "5"])     # => pass
    #   assert_includes_in_order(w{1 2 3 4 5}, ["1", /\[a-z]+/, "5"]) # => fail
    #
    def assert_includes_in_order(given, original, msg = nil)
      msg = message(msg) do
        "Expected #{mu_pp(original)} to include #{mu_pp(given)} in order"
      end
      assert _includes_in_order(original, given), msg
    end

    def refute_includes_in_order(given, original, msg = nil)
      msg = message(msg) do
        "Expected #{mu_pp(original)} to not include #{mu_pp(given)} in order"
      end
      refute _includes_in_order(original, given), msg
    end

    def assert_location(file, line)
      expected, actual = "#{file}:#{line}", "#{state.file}:#{state.line}"
      msg = "Expected location to be #{expected}, but was #{actual}"

      assert file == state.file && line == state.line, msg
    end

    private

    def _includes_in_order(original_collection, given_collection)
      given_collection.each_with_index do |given_item, i|
        index = case given_item
                when String
                  original_collection[i..-1].index(given_item)
                when Regexp
                  original_collection[i..-1].index { |it| it =~ given_item }
                end

        return false unless index
      end

      true
    end
  end
end
