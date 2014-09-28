module Byebug
  class SaveTestCase < TestCase
    def setup
      @example = -> do
        byebug
        a = 2
        a = 3
      end

      super

      enter 'break 2', 'break 3 if true', 'catch NoMethodError',
            'display 2 + 3', 'save save_output.txt'
      debug_proc(@example)
    end

    def teardown
      File.delete('save_output.txt')
    end

    def file_contents
      @file_contents ||= File.read('save_output.txt')
    end

    def test_save_records_regular_breakpoints
      assert_includes file_contents, "break #{__FILE__}:2"
    end

    def test_save_records_conditional_breakpoints
      assert_includes file_contents, "break #{__FILE__}:3 if true"
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
      debug_proc(@example)
      assert_includes File.read(RESTART_FILE), 'set autoirb false'
      File.delete(RESTART_FILE)
    end

    def test_save_without_a_filename_shows_a_message_with_the_file_used
      enter 'save'
      debug_proc(@example)
      check_output_includes "Saved to '#{RESTART_FILE}'"
      File.delete(RESTART_FILE)
    end
  end
end
