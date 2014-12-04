module Byebug
  #
  # Tests saving Byebug commands to a file.
  #
  class SaveTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    byebug
        3:    a = 2
        4:    a + 3
        5:  end
      EOC
    end

    def setup
      super

      enter 'break 3', 'break 4 if true', 'catch NoMethodError',
            'display 2 + 3', 'save save_output.txt'
      debug_code(program)
    end

    def teardown
      File.delete('save_output.txt')
    end

    def file_contents
      @file_contents ||= File.read('save_output.txt')
    end

    def test_save_records_regular_breakpoints
      assert_includes file_contents, "break #{example_fullpath}:3"
    end

    def test_save_records_conditional_breakpoints
      assert_includes file_contents, "break #{example_fullpath}:4 if true"
    end

    def test_save_records_catchpoints
      assert_includes file_contents, 'catch NoMethodError'
    end

    def test_save_records_displays
      assert_includes file_contents, 'display 2 + 3'
    end

    def test_save_records_current_state_of_settings
      assert_includes file_contents, 'set autoeval true'
      assert_includes file_contents, 'set basename false'
      assert_includes file_contents, 'set testing true'
      assert_includes file_contents, 'set autolist false'
      assert_includes file_contents, 'set autoirb false'
    end

    def test_save_shows_a_success_message
      check_output_includes "Saved to 'save_output.txt'"
    end

    def test_save_without_a_filename_uses_a_default_file
      enter 'save'
      debug_code(program)
      assert_includes File.read(RESTART_FILE), 'set autoirb false'
      File.delete(RESTART_FILE)
    end

    def test_save_without_a_filename_shows_a_message_with_the_file_used
      enter 'save'
      debug_code(program)
      check_output_includes "Saved to '#{RESTART_FILE}'"
      File.delete(RESTART_FILE)
    end
  end
end
