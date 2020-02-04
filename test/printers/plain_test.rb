# frozen_string_literal: true

require_relative "../test_helper"
require "minitest/mock"
require "byebug/helpers/string"

module Byebug
  #
  # Tests the plain text printer
  #
  class PrintersPlainTest < TestCase
    include Helpers::StringHelper

    def klass
      @klass ||= Printers::Plain
    end

    def printer
      @printer ||= klass.new
    end

    def yaml_plain
      deindent <<-YAML, leading_spaces: 8
        foo:
          bar: "plain {zee}, {uga} gaa"
          confirmations:
            okay: "Okay?"
        variable:
          variable: "{key}: {value}"
      YAML
    end

    def yaml_base
      deindent <<-YAML, leading_spaces: 8
        foo:
          bar: "base {zee}, {uga} gaa"
          boo: "{zee}, gau"
      YAML
    end

    def test_returns_correctly_translated_string
      with_dummy_yaml do
        assert_equal \
          "plain zuu, aga gaa\n",
          printer.print("foo.bar", zee: "zuu", uga: "aga")
      end
    end

    def test_add_yn_to_the_confirmation_strings
      with_dummy_yaml do
        assert_equal("Okay? (y/n) ", printer.print("foo.confirmations.okay"))
      end
    end

    def test_strings_inherited_from_base
      with_new_tempfile(yaml_plain) do |path_plain|
        with_new_tempfile(yaml_base) do |path_base|
          printer.stub(:contents_files, [path_plain, path_base]) do
            assert_equal("zuu, gau\n", printer.print("foo.boo", zee: "zuu"))
          end
        end
      end
    end

    def test_error_if_there_is_no_specified_path
      with_dummy_yaml do
        assert_raises(klass::MissedPath) { printer.print("foo.bla") }
      end
    end

    def test_error_if_there_is_no_specified_argument
      with_dummy_yaml do
        assert_raises(klass::MissedArgument) do
          printer.print("foo.bar", zee: "zuu")
        end
      end
    end

    def test_print_collection
      with_dummy_yaml do
        assert_equal(
          "plain 0, a gaa\nplain 1, b gaa\n",
          printer.print_collection(
            "foo.bar",
            [{ uga: "a" }, { uga: "b" }]
          ) do |item, index|
            item.merge(zee: index)
          end
        )
      end
    end

    def test_print_variables
      with_dummy_yaml do
        assert_equal \
          "a: b\nc: d\n",
          printer.print_variables([%w[a b], %w[c d]])
      end
    end

    def with_dummy_yaml
      with_new_tempfile(yaml_plain) do |path|
        printer.stub(:contents_files, [path]) { yield }
      end
    end
  end
end
