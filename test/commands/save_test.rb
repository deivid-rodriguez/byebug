# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests saving Byebug commands to a file.
  #
  class SaveTest < TestCase
    def program
      strip_line_numbers <<-RUBY
        1:  module Byebug
        2:    byebug
        3:    a = 2
        4:    a + 3
        5:  end
      RUBY
    end

    def cleanup(file)
      File.delete(file)
    end

    def file_contents
      File.read(Setting[:savefile])
    end

    def test_save_records_regular_breakpoints
      enter "break 3", "save"
      debug_code(program)

      assert_includes file_contents, "break #{example_path}:3"
      cleanup(Setting[:savefile])
    end

    def test_save_records_conditional_breakpoints
      enter "break 4 if true", "save"
      debug_code(program)

      assert_includes file_contents, "break #{example_path}:4 if true"
      cleanup(Setting[:savefile])
    end

    def test_save_records_catchpoints
      enter "catch NoMethodError", "save", "catch NoMethodError off"
      debug_code(program)

      assert_includes file_contents, "catch NoMethodError"
      cleanup(Setting[:savefile])
    end

    def test_save_records_displays
      enter "display 2 + 3", "save"
      debug_code(program) { clear_displays }

      assert_includes file_contents, "display 2 + 3"
      cleanup(Setting[:savefile])
    end

    def test_save_records_current_state_of_settings
      enter "save"
      debug_code(program)

      assert_includes file_contents, "set basename false"
      assert_includes file_contents, "set autolist true"
      assert_includes file_contents, "set autoirb false"
      cleanup(Setting[:savefile])
    end

    def test_save_shows_a_success_message
      enter "save"
      debug_code(program)

      check_output_includes "Saved to '#{Setting[:savefile]}'"
      cleanup(Setting[:savefile])
    end

    def test_save_without_a_filename_uses_a_default_file
      enter "save output.txt"
      debug_code(program)

      assert_includes File.read("output.txt"), "set autoirb false"
      cleanup("output.txt")
    end

    def test_save_without_a_filename_shows_a_message_with_the_file_used
      enter "save output.txt"
      debug_code(program)

      check_output_includes "Saved to 'output.txt'"
      cleanup("output.txt")
    end
  end
end
