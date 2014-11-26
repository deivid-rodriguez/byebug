module Byebug
  #
  # Tests for listing source files.
  #
  class ListTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test breakpoints
         4:    #
         5:    class TestExample
         6:      def build_percentage_string
         7:        '%1'
         8:      end
         9:    end
        10:
        11:    byebug
        12:
        13:    str = TestExample.new.build_percentage_string
        14:
        15:    str
        16:  end
      EOC
    end

    def test_lists_source_code_lines
      enter 'set listsize 3', 'list'
      debug_code(program)
      check_output_includes "[12, 14] in #{example_path}"
    end

    def test_listsize_is_not_set_if_parameter_is_not_an_integer
      enter 'set listsize 5.0', 'list'
      debug_code(program)
      check_output_doesnt_include "[12, 14] in #{example_path}"
    end

    def test_does_not_list_before_the_beginning_of_file
      enter 'cont 7', 'set listsize 15', 'list'
      debug_code(program)
      check_output_includes "[1, 15] in #{example_path}"
    end

    def test_does_not_list_after_the_end_of_file
      enter 'set listsize 13', 'list'
      debug_code(program)
      check_output_includes "[4, 16] in #{example_path}"
    end

    def test_lists_the_whole_file_if_number_of_lines_is_smaller_than_listsize
      enter 'set listsize 17', 'list'
      debug_code(program)
      check_output_includes "[1, 16] in #{example_path}"
    end

    def test_lists_forwards_after_the_second_call_to_list
      enter 'set listsize 3', 'cont 7', 'list', 'list'
      debug_code(program)
      check_output_includes "[9, 11] in #{example_path}"
    end

    def test_lists_surrounding_lines_after_the_first_call_to_list_minus
      enter 'set listsize 3', 'list-'
      debug_code(program)
      check_output_includes "[12, 14] in #{example_path}"
    end

    def test_lists_backwards_after_the_second_call_to_list_minus
      enter 'set listsize 3', 'list-', 'list-'
      debug_code(program)
      check_output_includes "[9, 11] in #{example_path}"
    end

    def test_lists_backwards_from_end_of_file
      enter 'set listsize 3', 'list 14-16', 'list -'
      debug_code(program)
      check_output_includes "[11, 13] in #{example_path}"
    end

    def test_lists_surrounding_lines_when_list_equals_is_called
      enter 'set listsize 3', 'list ='
      debug_code(program)
      check_output_includes "[12, 14] in #{example_path}"
    end

    def test_lists_specific_range_when_requested_in_hyphen_format
      enter 'list 6-8'
      debug_code(program)
      check_output_includes "[6, 8] in #{example_path}"
    end

    def test_lists_specific_range_when_requested_in_comma_format
      enter 'list 6,8'
      debug_code(program)
      check_output_includes "[6, 8] in #{example_path}"
    end

    def test_lists_nothing_if_unexistent_range_is_specified
      enter 'list 20,25'
      debug_code(program)
      check_error_includes 'Invalid line range'
      check_output_doesnt_include "[20, 25] in #{example_path}"
    end

    def test_lists_nothing_if_invalid_range_is_specified
      enter 'list 5,4'
      debug_code(program)
      check_error_includes 'Invalid line range'
      check_output_doesnt_include "[5, 4] in #{example_path}"
    end

    def test_list_proper_lines_when_range_around_specific_line_with_hyphen
      enter 'set listsize 3', 'list 4-'
      debug_code(program)
      check_output_includes "[3, 5] in #{example_path}"
    end

    def test_list_proper_lines_when_range_around_specific_line_with_comma
      enter 'set listsize 3', 'list 4,'
      debug_code(program)
      check_output_includes "[3, 5] in #{example_path}"
    end

    def test_shows_an_error_when_the_file_to_list_does_not_exist
      enter -> { state.file = 'blabla'; 'list 7-7' }
      debug_code(program)
      check_error_includes 'No sourcefile available for blabla'
    end

    def test_correctly_print_lines_containing_the_percentage_symbol
      enter 'list 7'
      debug_code(program)
      check_output_includes(/7:\s+'%1'/)
    end

    def replace_build_percentage_string_line_and_list_it
      cmd_after_replace(example_path, 7, "      '%11'", 'list 7-7')
    end

    def test_lists_file_changes
      enter -> { replace_build_percentage_string_line_and_list_it }

      debug_code(program)
      check_output_includes(/7:\s+'%11'/)
    end
  end
end
