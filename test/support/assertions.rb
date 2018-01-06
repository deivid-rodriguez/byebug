# frozen_string_literal: true

require "minitest/mock"

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
    #   assert_includes_in_order(%w(1 2 3 4 5), ["1", /\d+/, "5"])
    #
    # @example Failing assertion with array and regexp elements
    #   assert_includes_in_order(%w(1 2 3 4 5), ["1", /\[a-z]+/, "5"])
    #
    def assert_includes_in_order(given, original, msg = nil)
      msg = message(msg) do
        "Expected #{mu_pp(original)} to include #{mu_pp(given)} in order"
      end
      assert includes_in_order(given, original), msg
    end

    def refute_includes_in_order(given, original, msg = nil)
      msg = message(msg) do
        "Expected #{mu_pp(original)} to not include #{mu_pp(given)} in order"
      end
      refute includes_in_order(given, original), msg
    end

    def assert_location(file, line)
      expected = "#{file}:#{line}"
      actual = "#{frame.file}:#{frame.line}"
      msg = "Expected location to be #{expected}, but was #{actual}"

      assert file == frame.file && line == frame.line, msg
    end

    def assert_program_finished
      assert_nil context.backtrace, "Expected program to have finished"
    end

    def assert_calls(object, method, *expected_args, &block)
      check_calls(:includes, object, method, *expected_args, &block)
    end

    def refute_calls(object, method, *expected_args, &block)
      check_calls(:doesnt_include, object, method, *expected_args, &block)
    end

    private

    def check_calls(check_method, object, method, *expected_args)
      object.public_send(:stub, method, printer_stub(method)) do
        yield

        expected = Regexp.new(Regexp.escape(signature(method, *expected_args)))
        send(:"check_output_#{check_method}", expected)
      end
    end

    def signature(method, *args)
      return method.to_s unless args.any?

      [method, *args].join(" ")
    end

    def includes_in_order(collection, original_collection)
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

    def printer_stub(method_name)
      lambda do |*actual_args|
        Byebug::Context.interface.puts signature(method_name, *actual_args)
      end
    end
  end
end
