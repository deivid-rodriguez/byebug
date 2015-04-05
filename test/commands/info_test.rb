module Byebug
  #
  # Test info command.
  #
  class InfoTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test information about files.
         4:    #
         5:    class #{example_class}
         6:      def initialize
         7:        @foo = 'bar'
         8:        @bla = 'blabla'
         9:      end
        10:
        11:      def a(y, z)
        12:        w = '1' * 45
        13:        x = 2
        14:        w + x.to_s + y + z + @foo
        15:      end
        16:
        17:      def c
        18:        a = BasicObject.new
        19:        a
        20:      end
        21:
        22:      def b
        23:        a('a', 'b')
        24:        e = '%.2f'
        25:        e
        26:      end
        27:    end
        28:
        29:    byebug
        30:    i = #{example_class}.new
        31:    i.b
        32:    i.c
        33:  end
      EOC
    end

    def test_info_args_show_information_about_current_frame_arguments
      enter 'break 12', 'cont', 'info args'
      debug_code(program)
      check_output_includes 'y = "a"', 'z = "b"'
    end

    def test_info_breakpoints_shows_information_about_all_breakpoints
      enter 'break 12', 'break 13 if x == w', 'info breakpoints'
      debug_code(program)
      check_output_includes 'Num Enb What',
                            /\d+ +y   at #{example_path}:12/,
                            /\d+ +y   at #{example_path}:13 if x == w/
    end

    def test_info_breakpoints_with_ids_shows_information_on_specific_breakpoints
      enter 'b 12', 'b 13', -> { "info breakpoints #{Breakpoint.first.id}" }
      debug_code(program)
      check_output_includes 'Num Enb What', /\d+ +y   at #{example_path}:12/
      check_output_doesnt_include(/\d+ +y   at #{example_path}:13/)
    end

    def test_info_breakpoints_shows_a_message_when_no_breakpoints_found
      enter 'info breakpoints'
      debug_code(program)
      check_output_includes 'No breakpoints.'
    end

    def test_info_breakpoints_shows_error_if_specific_breakpoint_do_not_exist
      enter 'break 12', 'break 13', 'delete 100', 'info breakpoints 100'
      debug_code(program)
      check_error_includes 'No breakpoints found among list given'
    end

    def test_info_breakpoints_shows_hit_counts
      enter 'break 12', 'cont', 'info breakpoints'
      debug_code(program)
      check_output_includes(/\d+ +y   at #{example_path}:12/,
                            'breakpoint already hit 1 time')
    end

    def test_info_display_shows_all_display_expressions
      enter 'display 3 + 3', 'display a + b', 'info display'
      debug_code(program) { clear_displays }

      check_output_includes 'Auto-display expressions now in effect:',
                            'Num Enb Expression',
                            '1: y  3 + 3',
                            '2: y  a + b'
    end

    def test_info_display_shows_a_message_when_no_display_expressions_found
      enter 'info display'
      debug_code(program)
      check_output_includes 'There are no auto-display expressions now.'
    end

    def test_info_file_shows_basic_info_about_current_file
      enter 'info file'

      debug_code(program)
      check_output_includes "File #{example_path} (33 lines)"
    end

    def with_dummy_script
      dummy_script = Tempfile.new('dummy_script')
      dummy_script.write('sleep 0')
      dummy_script.close

      yield(dummy_script.path)
    ensure
      dummy_script.close
      dummy_script.unlink
    end

    def test_info_file_with_a_file_name_shows_basic_info_about_a_specific_file
      with_dummy_script do |script_name|
        enter "info file #{script_name}"
        debug_code(program)

        check_output_includes "File #{script_name} (1 line)"
      end
    end

    def test_info_file_shows_mtime_of_current_file
      enter 'info file'
      debug_code(program)

      check_output_includes \
        "Modification time: #{File.stat(example_path).mtime}"
    end

    def test_info_file_w_filename_shows_mtime_of_filename
      with_dummy_script do |script_name|
        enter "info file #{script_name}"
        debug_code(program)

        check_output_includes \
          "Modification time: #{File.stat(script_name).mtime}"
      end
    end

    def test_info_file_shows_sha1_signature_of_current_file
      enter 'info file'
      debug_code(program)

      check_output_includes \
        "Sha1 Signature: #{Digest::SHA1.hexdigest(example_path)}"
    end

    def test_info_file_w_filename_shows_sha1_signature_of_filename
      with_dummy_script do |script_name|
        enter "info file #{script_name}"
        debug_code(program)

        check_output_includes \
          "Sha1 Signature: #{Digest::SHA1.hexdigest(script_name)}"
      end
    end

    def test_info_file_shows_potential_breakpoint_lines_in_current_file
      enter 'info file'
      debug_code(program)
      expected_lines = [1, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 17, 18, 19, 20,
                        22, 23, 24, 25, 26, 27, 29, 30, 31, 32, 33].join('  ')

      check_output_includes 'Breakpoint line numbers:', *expected_lines
    end

    def test_info_file_w_filename_shows_potential_breakpoint_lines_in_filename
      with_dummy_script do |script_name|
        enter "info file #{script_name}"
        debug_code(program)

        check_output_includes 'Breakpoint line numbers:', '1'
      end
    end

    def test_info_file_does_not_show_any_info_if_filename_is_invalid
      enter 'info file blabla'
      debug_code(program)

      check_error_includes 'blabla is not a valid source file'
    end

    def test_info_line_shows_info_about_the_current_line
      enter 'break 12', 'cont', 'info line'
      debug_code(program)

      check_output_includes "Line 12 of \"#{example_path}\""
    end

    def test_info_program_shows_the_initial_stop_reason
      enter 'info program'
      debug_code(program)

      check_output_includes \
        "It stopped after stepping, next'ing or initial start."
    end

    def test_info_program_shows_an_error_if_the_program_is_crashed
      skip('for now')
    end

    def test_info_program_shows_the_step_stop_reason
      enter 'step', 'info program'
      debug_code(program)

      check_output_includes \
        'Program stopped.',
        "It stopped after stepping, next'ing or initial start."
    end

    def test_info_program_shows_the_breakpoint_stop_reason
      enter 'break 12', 'cont', 'info program'
      debug_code(program)

      check_output_includes 'Program stopped.', 'It stopped at a breakpoint.'
    end

    def program_raising
      strip_line_numbers <<-EOC
        byebug

        fail 'Bang'
      EOC
    end

    def test_info_program_shows_the_catchpoint_stop_reason
      enter 'catch RuntimeError', 'cont', 'info program', 'catch off', 'y'

      assert_raises(RuntimeError) { debug_code(program_raising) }
      check_output_includes 'Program stopped.', 'It stopped at a catchpoint.'
    end

    def test_info_alone_shows_help
      enter 'info', 'cont'
      debug_code(program)
      check_output_includes(/List of "info" subcommands:/)
    end
  end
end
