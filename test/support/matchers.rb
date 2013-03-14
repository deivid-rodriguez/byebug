module MiniTest::Assertions

  # This matcher checks that given collection is included into the original collection,
  # and in correct order. It accepts both strings and regexps.
  #
  # Examples:
  #
  #   assert_includes_in_order(%w{1 2 3 4 5}, %w{1 3 5})            # => pass
  #   assert_includes_in_order(%w{1 2 3 4 5}, %w{1 5 3})            # => fail
  #   assert_includes_in_order(w{1 2 3 4 5}, ["1", /\d+/, "5"])     # => pass
  #   assert_includes_in_order(w{1 2 3 4 5}, ["1", /\[a-z]+/, "5"]) # => fail
  #
  def assert_includes_in_order(given_collection, original_collection, msg = nil)
    msg = message(msg) do
      "Expected #{mu_pp(original_collection)} to include #{mu_pp(given_collection)} in order"
    end
    assert includes_in_order_result(original_collection, given_collection), msg
  end

  def refute_includes_in_order(given_collection, original_collection, msg = nil)
    msg = message(msg) do
      "Expected #{mu_pp(original_collection)} to not include #{mu_pp(given_collection)} in order"
    end
    refute includes_in_order_result(original_collection, given_collection), msg
  end


  private

    def includes_in_order_result(original_collection, given_collection)
      result = true
      given_collection.each do |given_item|
        result &&= case given_item
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

module MiniTest::Expectations
  infect_an_assertion :assert_includes_in_order, :must_include_in_order
  infect_an_assertion :refute_includes_in_order, :wont_include_in_order
end
