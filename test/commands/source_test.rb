require 'test_helper'

module Byebug
  #
  # Tests reading Byebug commands from a file.
  #
  class SourceTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    byebug
        3:
        4:    a = 2
        5:    a + 3
        6:  end
      EOC
    end

    def setup
      File.open('source_example.txt', 'w') do |f|
        f.puts 'break 4'
        f.puts 'break 5 if true'
      end

      super
    end

    def teardown
      File.delete('source_example.txt')
      super
    rescue
      retry
    end

    %w(source so).each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_runs_byebug_commands_from_file") do
        enter "#{cmd_alias} source_example.txt"

        debug_code(program) do
          assert_equal 4, Breakpoint.first.pos
          assert_equal 5, Breakpoint.last.pos
          assert_equal 'true', Breakpoint.last.expr
        end
      end

      define_method(:"test_#{cmd_alias}_shows_an_error_if_file_not_found") do
        enter "#{cmd_alias} blabla"
        debug_code(program)

        check_error_includes(/File ".*blabla" not found/)
      end

      define_method(:"test_#{cmd_alias}_without_arguments_shows_help") do
        enter 'source'
        debug_code(program)

        check_output_includes(
          /Executes file <file> containing byebug commands./)
      end
    end
  end
end
