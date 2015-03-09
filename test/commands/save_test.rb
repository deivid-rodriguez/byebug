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

      @filename = RESTART_FILE
    end

    def teardown
      File.delete(@filename)

      super
    end

    def file_contents
      @file_contents ||= File.read(RESTART_FILE)
    end

    def test_save_records_regular_breakpoints
      enter 'break 3', 'save'
      debug_code(program)

      assert_includes file_contents, "break #{example_path}:3"
    end

    def test_save_records_conditional_breakpoints
      enter 'break 4 if true', 'save'
      debug_code(program)

      assert_includes file_contents, "break #{example_path}:4 if true"
    end

    def test_save_records_catchpoints
      enter 'catch NoMethodError', 'save', 'catch NoMethodError off'
      debug_code(program)

      assert_includes file_contents, 'catch NoMethodError'
    end

    def test_save_records_displays
      enter 'display 2 + 3', 'save'
      debug_code(program) { clear_displays }

      assert_includes file_contents, 'display 2 + 3'
    end

    def test_save_records_current_state_of_settings
      enter 'save'
      debug_code(program)

      assert_includes file_contents, 'set autoeval true'
      assert_includes file_contents, 'set basename false'
      assert_includes file_contents, 'set autolist true'
      assert_includes file_contents, 'set autoirb false'
    end

    def test_save_shows_a_success_message
      enter 'save'
      debug_code(program)

      check_output_includes "Saved to '#{RESTART_FILE}'"
    end

    def test_save_without_a_filename_uses_a_default_file
      @filenaname = 'saved_output.txt'
      enter "save #{@filename}"
      debug_code(program)

      assert_includes File.read(@filename), 'set autoirb false'
    end

    def test_save_without_a_filename_shows_a_message_with_the_file_used
      @filenaname = 'saved_output.txt'
      enter "save #{@filename}"
      debug_code(program)

      check_output_includes "Saved to '#{@filename}'"
    end
  end
end
