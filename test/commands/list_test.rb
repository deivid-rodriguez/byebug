module Byebug
  class ListTestCase < TestCase
    def setup
      @example = -> do
        byebug
        a = 6
        a = 7
        a = 8
        a = 9
        a = 10
        a = 11
        a = 12
        a = 13
        a = 14
        a = 15
        a = 16
        a = 17
        a = 18
        a = 19
        a = 20
        a = 21
        a = 22
        a = 23
        a = 24
        a = 25
        a = '%26'
      end

      super
    end

    def lines_between(min, max, mark_current = true)
      lines = [*File.open(__FILE__)][min-1..max-1]
      numbers = (min..max).to_a
      output = numbers.zip(lines).map { |l| format("%2d: %s", l[0], l[1]) }
      if mark_current
        middle = (output.size/2.0).ceil
        output[middle] = "=> #{output[middle]}"
      end
      output
    end

    def test_lists_source_code_lines
      Setting[:listsize] = 10
      enter 'list'
      debug_proc(@example)
      check_output_includes "[1, 10] in #{__FILE__}"
    end

    def test_listsize_is_not_set_if_parameter_is_not_an_integer
      enter 'set listsize 15.0', 'list'
      debug_proc(@example)
      check_output_doesnt_include "[1, 15] in #{__FILE__}"
    end

    def test_moves_range_up_when_it_goes_before_beginning_of_file
      Setting[:listsize] = 12
      enter 'list'
      debug_proc(@example)
      check_output_includes "[1, 12] in #{__FILE__}"
    end

    def test_moves_range_down_when_it_goes_after_the_end_of_file
      skip "Can't test this with the current setup"
    end

    def test_lists_the_whole_file_if_number_of_lines_is_smaller_than_listsize
      Setting[:listsize] = 1000
      n_lines = %x{wc -l #{__FILE__}}.split.first.to_i
      enter 'list'
      debug_proc(@example)
      check_output_includes "[1, #{n_lines}] in #{__FILE__}"
    end

    def test_lists_surrounding_lines_after_the_first_call_to_list
      enter 'break 8', 'cont', 'list'
      debug_proc(@example)
      check_output_includes("[3, 12] in #{__FILE__}", *lines_between(3, 12))
    end

    def test_lists_forwards_after_the_second_call_to_list
      enter 'break 8', 'cont', 'list', 'list'
      debug_proc(@example)
      check_output_includes("[13, 22] in #{__FILE__}",
                            *lines_between(13, 22, false))
    end

    def test_lists_surrounding_lines_after_the_first_call_to_list_minus
      enter 'break 18', 'cont', 'list -'
      debug_proc(@example)
      check_output_includes("[13, 22] in #{__FILE__}", *lines_between(13, 22))
    end

    def test_lists_backwards_after_the_second_call_to_list_minus
      enter 'break 18', 'cont', 'list -', 'list -'
      debug_proc(@example)
      check_output_includes("[3, 12] in #{__FILE__}",
                            *lines_between(3, 12, false))
    end

    def test_lists_surrounding_lines_when_list_equals_is_called
      enter 'break 8', 'cont', 'list ='
      debug_proc(@example)
      check_output_includes("[3, 12] in #{__FILE__}", *lines_between(3, 12))
    end

    def test_lists_specific_range_when_requested_in_hyphen_format
      enter 'list 7-9'
      debug_proc(@example)
      check_output_includes("[7, 9] in #{__FILE__}",
                            *lines_between(7, 9, false))
    end

    def test_lists_specific_range_when_requested_in_comma_format
      enter 'list 7,9'
      debug_proc(@example)
      check_output_includes("[7, 9] in #{__FILE__}",
                            *lines_between(7, 9, false))
    end

    def test_lists_nothing_if_unexistent_range_is_specified
      enter 'list 500,505'
      debug_proc(@example)
      check_error_includes 'Invalid line range'
      check_output_doesnt_include "[500, 505] in #{__FILE__}"
      check_output_doesnt_include(/^500  \S/)
    end

    def test_lists_nothing_if_invalid_range_is_specified
      enter 'list 5,4'
      debug_proc(@example)
      check_output_includes "[5, 4] in #{__FILE__}"
    end

    def test_list_proper_lines_when_range_around_specific_line_with_hyphen
      enter 'list 17-'
      debug_proc(@example)
      check_output_includes("[12, 21] in #{__FILE__}",
                            *lines_between(12, 21, false))
    end

    def test_list_proper_lines_when_range_around_specific_line_with_comma
      enter 'list 17,'
      debug_proc(@example)
      check_output_includes("[12, 21] in #{__FILE__}",
                            *lines_between(12, 21, false))
    end

    def test_shows_an_error_when_the_file_to_list_does_not_exist
      enter -> { state.file = 'blabla'; 'list 7-7' }
      debug_proc(@example)
      check_error_includes 'No sourcefile available for blabla'
    end

    def test_correctly_print_lines_containing_the_percentage_symbol
      enter 'list 26'
      debug_proc(@example)
      check_output_includes "26:         a = '%26'"
    end
  end

  class ListTestCaseAutoreload < ListTestCase
    def setup
      super
      Setting[:autoreload] = true
      enter 'list' # force first reading of file
    end

    def test_lists_file_changes_with_autoreload_enabled
      enter -> do
        change_line_in_file(__FILE__, 7, '        a = 100')
        'list 7-7'
      end
      debug_proc(@example)
      check_output_includes(/7:\s+a = 100/)
      change_line_in_file(__FILE__, 7, '        a = 7')
    end
  end

  class ListTestCaseNoAutoreload < ListTestCase
    def setup
      super
      Setting[:autoreload] = false
      enter 'list' # force first reading of file
    end

    def test_does_not_list_file_changes_with_autoreload_disabled
      enter -> do
        change_line_in_file(__FILE__, 7, '        a = 100')
        'list 7-7'
      end
      debug_proc(@example)
      check_output_doesnt_include(/7:\s+a = 100/)
      change_line_in_file(__FILE__, 7, '        a = 7')
    end
  end
end
