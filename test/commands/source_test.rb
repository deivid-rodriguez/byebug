# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests reading Byebug commands from a file.
  #
  class SourceTest < TestCase
    def program
      strip_line_numbers <<-RUBY
        1:  module Byebug
        2:    byebug
        3:
        4:    a = 2
        5:    a + 3
        6:  end
      RUBY
    end

    def setup
      File.open("source_example.txt", "w") do |f|
        f.puts "break 4"
        f.puts "break 5 if true"
      end

      super
    end

    def teardown
      File.delete("source_example.txt")
      super
    rescue StandardError
      retry
    end

    def test_source_runs_byebug_commands_from_file
      enter "source source_example.txt"

      debug_code(program) do
        assert_equal 4, Breakpoint.first.pos
        assert_equal 5, Breakpoint.last.pos
        assert_equal "true", Breakpoint.last.expr
      end
    end

    def test_source_shows_an_error_if_file_not_found
      enter "source blabla"
      debug_code(program)

      check_error_includes(/File ".*blabla" not found/)
    end

    def test_source_without_arguments_shows_help
      enter "source"
      debug_code(program)

      check_output_includes("Restores a previously saved byebug session")
    end
  end
end
