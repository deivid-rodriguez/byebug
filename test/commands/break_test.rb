require 'test_helper'

module Byebug
  #
  # Tests adding breakpoints to methods
  #
  class BreakAtMethodsTest < TestCase
    def program
      strip_line_numbers <<-EOC
          1:  module Byebug
          2:    #
          3:    # Toy class to test breakpoints
          4:    #
          5:    class #{example_class}
          6:      def self.a(n)
          7:        2.times do
          8:          n += 1
          9:        end
         10:      end
         11:
         12:      def b
         13:        3
         14:      end
         15:    end
         16:
         17:    module #{example_module}
         18:      def self.c
         19:        1
         20:      end
         21:    end
         22:
         23:    byebug
         24:
         25:    #{example_class}.new.b
         26:    #{example_class}.a(1)
         27:    #{example_module}.c
         28:  end
      EOC
    end

    def test_break_with_instance_method_stops_at_correct_place
      enter "break #{example_class}#b", 'cont'

      debug_code(program) { assert_location example_path, 12 }
    end

    def test_break_with_namespaced_instance_method_stops_at_correct_place
      enter "break Byebug::#{example_class}#b", 'cont'

      debug_code(program) { assert_location example_path, 12 }
    end

    def test_break_with_class_method_stops_at_correct_place
      enter "break #{example_class}.a", 'cont'

      debug_code(program) { assert_location example_path, 6 }
    end

    def test_break_with_namespaced_class_method_stops_at_correct_place
      enter "break Byebug::#{example_class}.a", 'cont'

      debug_code(program) { assert_location example_path, 6 }
    end

    def test_break_with_module_method_stops_at_correct_place
      enter "break #{example_module}.c", 'cont'

      debug_code(program) { assert_location(example_path, 18) }
    end

    def test_break_with_namespaced_module_method_stops_at_correct_place
      enter "break Byebug::#{example_module}.c", 'cont'

      debug_code(program) { assert_location example_path, 18 }
    end

    def test_break_with_a_method_does_not_stop_at_blocks_in_the_method
      enter "break #{example_class}.a", 'cont', 'break 8', 'cont'

      debug_code(program) { assert_location example_path, 8 }
    end

    def test_setting_breakpoint_to_an_undefined_class_creates_breakpoint
      enter 'break B.a'
      debug_code(program)

      check_output_includes(/Created breakpoint/)
    end

    def test_setting_breakpoint_to_an_undefined_class_shows_error_message
      enter 'break ::B.a'
      debug_code(program)

      check_error_includes 'Warning: breakpoint source is not yet defined'
    end

    def test_setting_breakpoint_to_invalid_location_does_not_create_breakpoint
      enter 'break foo'

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    def test_setting_breakpoint_to_invalid_location_shows_an_error
      enter 'break foo'
      debug_code(program)

      check_error_includes 'Invalid breakpoint location'
    end
  end

  #
  # Tests adding breakpoints to lines
  #
  class BreakAtLinesTest < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test breakpoints
         4:    #
         5:    class #{example_class}
         6:      def self.a
         7:        y = 1
         8:        z = 2
         9:        y + z
        10:      end
        11:    end
        12:
        13:    byebug
        14:
        15:    #{example_class}.a
        16:  end
      EOC
    end

    def test_setting_breakpoint_sets_correct_fields
      enter 'break 7'

      debug_code(program) do
        b = Breakpoint.first
        exp = [b.pos, b.source, b.expr, b.hit_count, b.hit_value, b.enabled?]
        act = [7, example_path, nil, 0, 0, true]
        assert_equal act, exp
      end
    end

    def test_setting_breakpoint_using_shortcut_properly_adds_the_breakpoint
      enter 'break 7'

      debug_code(program) { assert_equal 1, Byebug.breakpoints.size }
    end

    def test_setting_breakpoint_to_nonexistent_line_does_not_create_breakpoint
      enter 'break 1000'

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    def test_setting_breakpoint_to_nonexistent_file_does_not_create_breakpoint
      enter 'break asf:324'

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    def test_setting_breakpoint_to_nonexistent_file_shows_an_error
      enter 'break asf:234'
      debug_code(program)

      check_error_includes 'No file named asf'
    end

    def test_setting_breakpoint_with_bad_relative_path_doesnt_crash
      enter 'break ../relative/path.rb:8'
      debug_code(program)

      check_error_includes 'No file named ../relative/path.rb'
    end

    def test_setting_breakpoint_with_relative_path_adds_the_breakpoint
      enter 'break ./test/commands/break_test.rb:8'
      debug_code(program)

      check_output_includes(/Created breakpoint/)
    end

    def test_setting_breakpoint_with_space_in_path_adds_the_breakpoint
      with_new_file('hello world.rb', 'puts "Hello World!"') do
        enter 'break hello world.rb:1'
        debug_code(program)

        check_output_includes(/Created breakpoint/)
      end
    end

    def test_setting_breakpoint_to_nonexistent_file_with_space_shows_an_error
      enter 'break /this path/isnt there/abc xyz:8'
      debug_code(program)

      check_error_includes 'No file named /this path/isnt there/abc xyz'
    end

    def test_setting_breakpoint_to_path_with_colons_does_not_crash
      enter 'break C:/bb.rb:1'
      debug_code(program)

      check_error_includes 'No file named C:/bb.rb'
    end

    def test_setting_breakpoint_to_invalid_line_does_not_create_breakpoint
      enter 'break 14'

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    def test_stops_at_correct_place_when_breakpoint_set_in_a_regular_line
      enter 'break 7', 'cont'

      debug_code(program) { assert_location example_path, 7 }
    end

    def test_stops_at_correct_place_when_breakpoint_set_at_method_return
      enter 'break 10', 'cont'

      debug_code(program) { assert_location example_path, 10 }
    end

    def test_shows_return_value_information_when_breakpoint_set_at_method_return
      enter 'break 10', 'cont'
      debug_code(program)

      check_output_includes 'Return value is: 3'
    end

    def test_breaking_w_byebug_keyword_stops_at_the_next_line
      debug_code(program) { assert_equal 15, frame.line }
    end

    def test_conditional_breakpoint_stops_if_condition_is_true
      enter 'break 8 if y == 1', 'break 9', 'cont'

      debug_code(program) { assert_equal 8, frame.line }
    end

    def test_conditional_breakpoint_is_ignored_if_condition_is_false
      enter 'break 8 if y == 2', 'break 9', 'cont'

      debug_code(program) { assert_equal 9, frame.line }
    end

    def test_setting_conditional_breakpoint_using_wrong_expression_ignores_it
      enter 'break 8 if y -=) 1', 'break 9', 'cont'

      debug_code(program) { assert_equal 9, frame.line }
    end

    def test_setting_conditional_breakpoint_using_wrong_expression_shows_error
      enter 'break 11 if y -=) 1'
      debug_code(program)

      check_error_includes 'Incorrect expression "y -=) 1"; breakpoint disabled'
    end

    def test_shows_info_about_setting_breakpoints_when_using_just_break
      enter 'break', 'cont'
      debug_code(program)

      check_output_includes(/b\[reak\] \[file:\]line \[if expr\]/)
    end

    def test_setting_breakpoint_uses_new_source
      enter -> { cmd_after_replace(example_path, 7, '', 'break 7') }

      debug_code(program) { assert_empty Byebug.breakpoints }
    end

    def test_setting_breakpoint_prints_confirmation_message
      enter 'break 7'
      debug_code(program) { @id = Breakpoint.first.id }

      check_output_includes(/Created breakpoint #{@id}/)
    end

    def test_setting_breakpoint_to_nonexistent_line_shows_an_error
      enter 'break 1000'
      debug_code(program)

      check_error_includes "There are only 16 lines in file #{example_path}"
    end

    def test_setting_breakpoint_to_invalid_line_shows_an_error
      enter 'break 14'
      debug_code(program)

      check_error_includes \
        "Line 14 is not a valid breakpoint in file #{example_path}"
    end
  end

  #
  # Tests using the byebug keyword at the end of a method
  #
  class BreakWithByebugKeywordAtMethodEndTest < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test byebug at the end of a method
         4:    #
         5:    class #{example_class}
         6:      def a
         7:        byebug
         8:      end
         9:
        10:      new.a
        11:    end
        12:  end
      EOC
    end

    def test_stops_right_before_method_returns
      debug_code(program) { assert_equal 8, frame.line }
    end

    def test_shows_nil_return_value
      debug_code(program)

      check_output_includes 'Return value is: nil'
    end
  end

  #
  # Tests using the byebug keyword at the end of a block
  #
  class BreakWithByebugKeywordAtBlockEndTest < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test byebug at the end of a block
         4:    #
         5:    class #{example_class}
         6:      def method_that_yields(b)
         7:        yield(b)
         8:        0
         9:      end
        10:
        11:      new.method_that_yields(0) do |n|
        12:        sleep n
        13:        byebug
        14:      end
        15:    end
        16:  end
      EOC
    end

    def test_stops_right_before_block_returns
      debug_code(program) { assert_equal 14, frame.line }
    end

    def test_shows_nil_return_value
      debug_code(program)

      check_output_includes 'Return value is: nil'
    end
  end

  #
  # Tests using the byebug keyword at the end of a class definition
  #
  class BreakWithByebugKeywordAtClassDefinitionEndTest < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test byebug at the end of a class
         4:    #
         5:    class #{example_class}
         6:      def a
         7:        0
         8:      end
         9:
        10:      byebug
        11:    end
        12:  end
      EOC
    end

    def test_stops_right_before_class_definition_ends
      debug_code(program) { assert_equal 11, frame.line }
    end

    def test_does_not_show_return_value_information
      debug_code(program)

      check_output_doesnt_include 'Return value is: nil'
    end
  end
end
