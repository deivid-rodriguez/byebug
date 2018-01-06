# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Test info command.
  #
  class InfoTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test information about files.
         4:    #
         5:    class #{example_class}
         6:      def initialize
         7:        @foo = "bar"
         8:        @bla = "blabla"
         9:      end
        10:
        11:      def a(y, z)
        12:        w = "1" * 45
        13:        x = 2
        14:        w + x.to_s + y + z + @foo
        15:      end
        16:
        17:      def b
        18:        a("a", "b")
        19:        e = "%.2f"
        20:        e
        21:      end
        22:    end
        23:
        24:    byebug
        25:    i = #{example_class}.new
        26:    i.b
        27:  end
      RUBY
    end

    def test_info_breakpoints_shows_information_about_all_breakpoints
      enter "break 12", "break 13 if x == w", "info breakpoints"
      debug_code(program)

      check_output_includes "Num Enb What",
                            /\d+ +y   at #{example_path}:12/,
                            /\d+ +y   at #{example_path}:13 if x == w/
    end

    def test_info_breakpoints_with_ids_shows_information_on_specific_breakpoints
      enter "b 12", "b 13", -> { "info breakpoints #{Breakpoint.first.id}" }
      debug_code(program)

      check_output_includes "Num Enb What", /\d+ +y   at #{example_path}:12/
      check_output_doesnt_include(/\d+ +y   at #{example_path}:13/)
    end

    def test_info_breakpoints_shows_a_message_when_no_breakpoints_found
      enter "info breakpoints"
      debug_code(program)

      check_output_includes "No breakpoints."
    end

    def test_info_breakpoints_shows_error_if_specific_breakpoint_do_not_exist
      enter "break 12", "break 13", "delete 100", "info breakpoints 100"
      debug_code(program)

      check_error_includes "No breakpoints found among list given"
    end

    def test_info_breakpoints_shows_hit_counts
      enter "break 12", "cont", "info breakpoints"
      debug_code(program)

      check_output_includes(/\d+ +y   at #{example_path}:12/,
                            "breakpoint already hit 1 time")
    end

    def test_info_display_shows_all_display_expressions
      enter "display 3 + 3", "display a + b", "info display"
      debug_code(program) { clear_displays }

      check_output_includes "Auto-display expressions now in effect:",
                            "Num Enb Expression",
                            "1: y  3 + 3",
                            "2: y  a + b"
    end

    def test_info_display_shows_a_message_when_no_display_expressions_found
      enter "info display"
      debug_code(program)

      check_output_includes "There are no auto-display expressions now."
    end

    def test_info_line_shows_info_about_the_current_line
      enter "break 12", "cont", "info line"
      debug_code(program)

      check_output_includes "Line 12 of \"#{example_path}\""
    end

    def test_info_program_shows_the_initial_stop_reason
      enter "info program"
      debug_code(program)

      check_output_includes \
        "It stopped after stepping, next'ing or initial start."
    end

    def test_info_program_shows_the_step_stop_reason
      enter "step", "info program"
      debug_code(program)

      check_output_includes \
        "Program stopped.",
        "It stopped after stepping, next'ing or initial start."
    end

    def test_info_program_shows_the_breakpoint_stop_reason
      enter "break 12", "cont", "info program"
      debug_code(program)

      check_output_includes "Program stopped.", "It stopped at a breakpoint."
    end

    def test_info_alone_shows_help
      enter "info", "cont"
      debug_code(program)

      check_output_includes \
        "Shows several informations about the program being debugged"
    end
  end

  #
  # Tests "info file" command
  #
  class InfoFileTest < TestCase
    def program
      strip_line_numbers <<-RUBY
        1:  module Byebug
        2:    byebug
        3:    3
        4:  end
      RUBY
    end

    def test_info_file_shows_basic_info_about_current_file
      enter "info file"
      debug_code(program)

      check_output_includes "File #{example_path} (4 lines)"
    end

    def test_info_file_with_a_file_name_shows_basic_info_about_a_specific_file
      with_new_tempfile("sleep 0") do |script_name|
        enter "info file #{script_name}"
        debug_code(program)

        check_output_includes "File #{script_name} (1 line)"
      end
    end

    def test_info_file_shows_mtime_of_current_file
      enter "info file"
      debug_code(program)

      check_output_includes \
        "Modification time: #{File.stat(example_path).mtime}"
    end

    def test_info_file_w_filename_shows_mtime_of_filename
      with_new_tempfile("sleep 0") do |script_name|
        enter "info file #{script_name}"
        debug_code(program)

        check_output_includes \
          "Modification time: #{File.stat(script_name).mtime}"
      end
    end

    def test_info_file_shows_sha1_signature_of_current_file
      enter "info file"
      debug_code(program)

      check_output_includes \
        "Sha1 Signature: #{Digest::SHA1.hexdigest(example_path)}"
    end

    def test_info_file_w_filename_shows_sha1_signature_of_filename
      with_new_tempfile("sleep 0") do |script_name|
        enter "info file #{script_name}"
        debug_code(program)

        check_output_includes \
          "Sha1 Signature: #{Digest::SHA1.hexdigest(script_name)}"
      end
    end

    def test_info_file_shows_potential_breakpoint_lines_in_current_file
      enter "info file"
      debug_code(minimal_program)

      check_output_includes "Breakpoint line numbers: 1 2 4 5"
    end

    def test_info_file_w_filename_shows_potential_breakpoint_lines_in_filename
      with_new_tempfile("sleep 0") do |script_name|
        enter "info file #{script_name}"
        debug_code(program)

        check_output_includes "Breakpoint line numbers: 1"
      end
    end

    def test_info_file_does_not_show_any_info_if_filename_is_invalid
      enter "info file blabla"
      debug_code(program)

      check_error_includes "blabla is not a valid source file"
    end

    def test_info_file_with_a_file_name_with_space_doesnt_fail
      enter "info file /filename/with space"
      debug_code(program)

      check_error_includes "/filename/with space is not a valid source file"
    end
  end

  #
  # Tests info command on crashed programs
  #
  class InfoCrashedTest < TestCase
    def program_raising
      strip_line_numbers <<-RUBY
        byebug

        fail "Bang"
      RUBY
    end

    def test_info_program_shows_the_catchpoint_stop_reason_for_crashed_programs
      enter "catch RuntimeError", "cont", "info program", "catch off", "y"

      assert_raises(RuntimeError) { debug_code(program_raising) }
      check_output_includes "Program stopped.", "It stopped at a catchpoint."
    end
  end
end
