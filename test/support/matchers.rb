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

    private

    def _includes_in_order(original_collection, given_collection)
      result = true
      given_collection.each do |given_item|
        result &&=
          case given_item
          when String
            index = original_collection.index(given_item)
            if index
              original_collection = original_collection[(index + 1)..-1]
              true
            else
              false
            end
          when Regexp
            index = nil
            original_collection.each_with_index do |original_item, i|
              if original_item =~ given_item
                index = i
                break
              end
            end
            if index
              original_collection = original_collection[(index + 1)..-1]
              true
            else
              false
            end
          else
            false
          end
      end
      result
    end
  end
end
