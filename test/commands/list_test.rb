# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests for listing source files.
  #
  class ListTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test breakpoints
         4:    #
         5:    class #{example_class}
         6:      def build_percentage_string
         7:        "%1"
         8:      end
         9:    end
        10:
        11:    byebug
        12:
        13:    str = #{example_class}.new.build_percentage_string
        14:
        15:    str
        16:  end
      RUBY
    end

    def test_lists_source_code_lines
      with_setting :listsize, 3 do
        enter "list"
        debug_code(program)

        check_output_includes "[12, 14] in #{example_path}"
      end
    end

    def test_listsize_is_not_set_if_parameter_is_not_an_integer
      with_setting :listsize, 3 do
        enter "set listsize 5.0", "list"
        debug_code(program)

        check_output_doesnt_include "[11, 15] in #{example_path}"
      end
    end

    def test_does_not_list_before_the_beginning_of_file
      with_setting :listsize, 15 do
        enter "cont 7", "list"
        debug_code(program)

        check_output_includes "[1, 15] in #{example_path}"
      end
    end

    def test_does_not_list_after_the_end_of_file
      with_setting :listsize, 13 do
        enter "list"
        debug_code(program)

        check_output_includes "[4, 16] in #{example_path}"
      end
    end

    def test_lists_the_whole_file_if_number_of_lines_is_smaller_than_listsize
      with_setting :listsize, 17 do
        enter "list"
        debug_code(program)

        check_output_includes "[1, 16] in #{example_path}"
      end
    end

    def test_lists_forwards_after_the_second_call_to_list
      with_setting :listsize, 3 do
        enter "cont 7", "list", "list"
        debug_code(program)

        check_output_includes "[9, 11] in #{example_path}"
      end
    end

    def test_lists_surrounding_lines_after_the_first_call_to_list_minus
      with_setting :listsize, 3 do
        enter "list-"
        debug_code(program)

        check_output_includes "[12, 14] in #{example_path}"
      end
    end

    def test_lists_backwards_after_the_second_call_to_list_minus
      with_setting :listsize, 3 do
        enter "list-", "list-"
        debug_code(program)

        check_output_includes "[9, 11] in #{example_path}"
      end
    end

    def test_lists_backwards_from_end_of_file
      with_setting :listsize, 3 do
        enter "list 14-16", "list -"
        debug_code(program)

        check_output_includes "[11, 13] in #{example_path}"
      end
    end

    def test_lists_surrounding_lines_when_list_equals_is_called
      with_setting :listsize, 3 do
        enter "list ="
        debug_code(program)

        check_output_includes "[12, 14] in #{example_path}"
      end
    end

    def test_lists_specific_range_when_requested_in_hyphen_format
      enter "list 6-8"
      debug_code(program)

      check_output_includes "[6, 8] in #{example_path}"
    end

    def test_lists_specific_range_when_requested_in_comma_format
      enter "list 6,8"
      debug_code(program)

      check_output_includes "[6, 8] in #{example_path}"
    end

    def test_lists_nothing_if_unexistent_range_is_specified
      enter "list 20,25"
      debug_code(program)

      check_error_includes '"List" argument "20" needs to be at most 16'
      check_output_doesnt_include "[20, 25] in #{example_path}"
    end

    def test_lists_nothing_if_invalid_range_is_specified
      enter "list 5,4"
      debug_code(program)

      check_error_includes "Invalid line range"
      check_output_doesnt_include "[5, 4] in #{example_path}"
    end

    def test_list_proper_lines_when_range_around_specific_line_with_hyphen
      with_setting :listsize, 3 do
        enter "list 4-"
        debug_code(program)

        check_output_includes "[3, 5] in #{example_path}"
      end
    end

    def test_list_proper_lines_when_range_around_specific_line_with_comma
      with_setting :listsize, 3 do
        enter "list 4,"
        debug_code(program)

        check_output_includes "[3, 5] in #{example_path}"
      end
    end

    def test_correctly_print_lines_containing_the_percentage_symbol
      enter "list 7"
      debug_code(program)

      check_output_includes(/7:\s+"%1"/)
    end

    def test_shows_error_when_invoked_with_invalid_syntax
      enter "list rdfe87"
      debug_code(program)

      check_error_includes(/needs to be a number/)
    end

    def test_gives_back_a_prompt_when_invoked_with_invalid_syntax
      enter "list rdfe87"

      debug_code(program) { assert_equal 13, frame.line }
    end

    def replace_build_percentage_string_line_and_list_it
      cmd_after_replace(example_path, 7, "      \"%11\"", "list 7-7")
    end

    def test_lists_file_changes
      skip
      enter -> { replace_build_percentage_string_line_and_list_it }
      debug_code(program)

      check_output_includes(/7:\s+"%11"/)
    end
  end
end
