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
         5:    class TestExample
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
        27:
        28:      def d
        29:        fail 'bang'
        30:      rescue
        31:      end
        32:    end
        33:
        34:    byebug
        35:    i = TestExample.new
        36:    i.b
        37:    i.c
        38:    i.d
        39:  end
      EOC
    end

    def basic
      lines = File.foreach(example_fullpath)
      "File #{example_fullpath} (#{lines.count} lines)"
    end

    def files
      Filecache.cached_files.sort
    end

    def mtime
      File.stat(example_fullpath).mtime.to_s
    end

    def sha1
      Digest::SHA1.hexdigest(example_fullpath)
    end

    def breakpoint_numbers
      columnize(Filecache.stopping_points(example_fullpath).sort,
                Byebug::Setting[:width])
    end

    include Columnize

    def test_info_about_all_args
      enter 'break 12', 'cont', 'info args'
      debug_code(program)
      check_output_includes 'y = "a"', 'z = "b"'
    end

    def test_info_about_all_breakpoints
      enter 'break 37', 'break 38 if y == z', 'info breakpoints'
      debug_code(program)
      check_output_includes 'Num Enb What',
                            /\d+ +y   at #{example_fullpath}:37/,
                            /\d+ +y   at #{example_fullpath}:38 if y == z/
    end

    def test_info_about_specific_breakpoints
      enter 'b 37', 'b 38', -> { "info breakpoints #{Breakpoint.first.id}" }
      debug_code(program)
      check_output_includes 'Num Enb What',
                            /\d+ +y   at #{example_fullpath}:37/
      check_output_doesnt_include(/\d+ +y   at #{example_fullpath}:38/)
    end

    def test_info_breakpoints_shows_a_message_when_no_breakpoints_found
      enter 'info breakpoints'
      debug_code(program)
      check_output_includes 'No breakpoints.'
    end

    def test_info_breakpoints_shows_error_if_specific_breakpoint_do_not_exist
      enter 'break 37', 'info breakpoints 100'
      debug_code(program)
      check_error_includes 'No breakpoints found among list given'
    end

    def test_info_breakpoints_shows_hit_counts
      enter 'break 38', 'cont', 'info breakpoints'
      debug_code(program)
      check_output_includes(/\d+ +y   at #{example_fullpath}:38/,
                            'breakpoint already hit 1 time')
    end

    def test_info_display_shows_all_display_expressions
      enter 'display 3 + 3', 'display a + b', 'info display'
      debug_code(program)
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

    def test_info_files_shows_all_files_read_in
      enter 'list' # explicitly load current file into cache
      enter 'info files'
      debug_code(program) do
        check_output_includes basic, mtime
        check_output_doesnt_include breakpoint_numbers, sha1
      end
    end

    def test_info_file_without_args_shows_basic_info_about_current_file
      enter 'info file'
      debug_code(program) do
        check_output_includes basic
        check_output_doesnt_include breakpoint_numbers, mtime, sha1
      end
    end

    def test_info_file_with_a_file_name_shows_basic_info_about_a_specific_file
      enter "info file #{example_fullpath}"
      debug_code(program) do
        check_output_includes basic
        check_output_doesnt_include breakpoint_numbers, mtime, sha1
      end
    end

    def test_info_file_mtime_shows_mtime_of_a_specific_file
      enter "info file #{example_fullpath} mtime"
      debug_code(program) do
        check_output_includes basic, mtime
        check_output_doesnt_include breakpoint_numbers, sha1
      end
    end

    def test_info_file_sha1_shows_sha1_signature_of_a_specific_file
      enter "info file #{example_fullpath} sha1"
      debug_code(program) do
        check_output_includes basic, sha1
        check_output_doesnt_include breakpoint_numbers, mtime
      end
    end

    def test_info_file_breakpoints_shows_breakpoints_in_a_specific_file
      enter 'break 37', 'break 38',
            "info file #{example_fullpath} breakpoints"
      debug_code(program) do
        check_output_includes(
          /Created breakpoint \d+ at #{example_fullpath}:37/,
          /Created breakpoint \d+ at #{example_fullpath}:38/,
          basic,
          'breakpoint line numbers:', breakpoint_numbers)
        check_output_doesnt_include mtime, sha1
      end
    end

    def test_info_file_all_shows_all_available_info_about_a_specific_file
      enter "info file #{example_fullpath} all"
      debug_code(program) do
        check_output_includes basic, breakpoint_numbers, mtime, sha1
      end
    end

    def test_info_file_does_not_show_any_info_if_parameter_is_invalid
      enter "info file #{example_fullpath} blabla"
      debug_code(program)
      check_error_includes 'Invalid parameter blabla'
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

    def test_info_program_shows_the_step_stop_reason
      enter 'step', 'info program'
      debug_code(program)
      check_output_includes \
        'Program stopped.',
        "It stopped after stepping, next'ing or initial start."
    end

    def test_info_program_shows_the_breakpoint_stop_reason
      enter 'break 37', 'cont', 'info program'
      debug_code(program)
      check_output_includes 'Program stopped.', 'It stopped at a breakpoint.'
    end

    def test_info_program_shows_the_catchpoint_stop_reason
      enter 'catch Exception', 'cont', 'info program'
      debug_code(program)
      check_output_includes 'Program stopped.', 'It stopped at a catchpoint.'
    end

    def test_shows_an_error_if_the_program_is_crashed
      skip('for now')
    end

    def test_shows_help_when_typing_just_info
      enter 'info', 'cont'
      debug_code(program)
      check_output_includes(/List of "info" subcommands:/)
    end
  end
end
