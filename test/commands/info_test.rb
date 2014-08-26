module Byebug
  class InfoExample
    def initialize
      @foo = 'bar'
      @bla = 'blabla'
    end

    def a(y, z)
      w = '1' * 45
      x = 2
      w + x.to_s + y + z + @foo
    end

    def c
      a = BasicObject.new
      a
    end

    def b
      a('a', 'b')
      e = "%.2f"
      e
    end

    def d
      raise 'bang'
    rescue
    end
  end

  class InfoTestCase < TestCase
    include Columnize

    def setup
      @example = -> do
        byebug
        i = InfoExample.new
        i.b
        i.c
        i.d
      end

      super
    end

    def test_info_about_all_args
      enter 'break 11', 'cont', 'info args'
      debug_proc(@example)
      check_output_includes 'y = "a"', 'z = "b"'
    end

    def test_info_about_all_breakpoints
      enter 'break 38', 'break 39 if y == z', 'info breakpoints'
      debug_proc(@example)
      check_output_includes 'Num Enb What',
                            /\d+ +y   at #{__FILE__}:38/,
                            /\d+ +y   at #{__FILE__}:39 if y == z/
    end

    def test_info_about_specific_breakpoints
      enter 'b 38', 'b 39', -> { "info breakpoints #{Breakpoint.first.id}" }
      debug_proc(@example)
      check_output_includes 'Num Enb What', /\d+ +y   at #{__FILE__}:38/
      check_output_doesnt_include(/\d+ +y   at #{__FILE__}:39/)
    end

    def test_info_breakpoints_shows_a_message_when_no_breakpoints_found
      enter 'info breakpoints'
      debug_proc(@example)
      check_output_includes 'No breakpoints.'
    end

    def test_info_breakpoints_shows_error_if_specific_breakpoint_do_not_exist
      enter 'break 38', 'info breakpoints 100'
      debug_proc(@example)
      check_error_includes 'No breakpoints found among list given'
    end

    def test_info_breakpoints_shows_hit_counts
      enter 'break 39', 'cont', 'info breakpoints'
      debug_proc(@example)
      check_output_includes(
        /\d+ +y   at #{__FILE__}:39/, 'breakpoint already hit 1 time')
    end

    def test_info_display_shows_all_display_expressions
      enter 'display 3 + 3', 'display a + b', 'info display'
      debug_proc(@example)
      check_output_includes "Auto-display expressions now in effect:",
                            'Num Enb Expression',
                            '1: y  3 + 3',
                            '2: y  a + b'
    end

    def test_info_display_shows_a_message_when_no_display_expressions_found
      enter 'info display'
      debug_proc(@example)
      check_output_includes 'There are no auto-display expressions now.'
    end

    def files
      @files ||= SCRIPT_LINES__.keys.uniq.sort
    end

    %w(file files).each do |subcmd_alias|
      define_method(:"test_info_#{subcmd_alias}_shows_all_files_read_in") do
        enter 'list' # list command explicitly reloads current file into cache
        enter "info #{subcmd_alias}"
        debug_proc(@example)
        check_output_includes "File #{__FILE__}", File.stat(__FILE__).mtime.to_s
      end
    end

    def filename
      @filename ||= "File #{__FILE__}"
    end

    def lines
      @lines ||= "#{File.foreach(__FILE__).count} lines"
    end

    def mtime
      @mtime ||= File.stat(__FILE__).mtime.to_s
    end

    def sha1
      @sha1 ||= Digest::SHA1.hexdigest(__FILE__)
    end

    def breakpoint_line_numbers
      @breakpoint_line_numbers ||=
        columnize(LineCache.trace_line_numbers(__FILE__).to_a.sort,
                  Byebug::Setting[:width])
    end

    def test_info_file_basic_shows_basic_info_about_a_specific_file
      enter "info file #{__FILE__} basic"
      debug_proc(@example)
      check_output_includes filename, lines
      check_output_doesnt_include breakpoint_line_numbers, mtime, sha1
    end

    def test_info_file_lines_shows_number_of_lines_in_a_specific_file
      enter "info file #{__FILE__} lines"
      debug_proc(@example)
      check_output_includes filename, lines
      check_output_doesnt_include breakpoint_line_numbers, mtime, sha1
    end

    def test_info_file_mtime_shows_mtime_of_a_specific_file
      enter "info file #{__FILE__} mtime"
      debug_proc(@example)
      check_output_includes filename, mtime
      check_output_doesnt_include lines, breakpoint_line_numbers, sha1
    end

    def test_info_file_sha1_shows_sha1_signature_of_a_specific_file
      enter "info file #{__FILE__} sha1"
      debug_proc(@example)
      check_output_includes filename, sha1
      check_output_doesnt_include lines, breakpoint_line_numbers, mtime
    end

    def test_info_file_breakpoints_shows_breakpoints_in_a_specific_file
      enter 'break 38', 'break 39', "info file #{__FILE__} breakpoints"
      debug_proc(@example)
      check_output_includes(
        /Created breakpoint \d+ at #{__FILE__}:38/,
        /Created breakpoint \d+ at #{__FILE__}:39/,
        filename,
        'breakpoint line numbers:', breakpoint_line_numbers)
      check_output_doesnt_include lines, mtime, sha1
    end

    def test_info_file_all_shows_all_available_info_about_a_specific_file
      enter "info file #{__FILE__} all"
      debug_proc(@example)
      check_output_includes \
        filename, lines, breakpoint_line_numbers, mtime, sha1
    end

    def test_info_file_does_not_show_any_info_if_parameter_is_invalid
      enter "info file #{__FILE__} blabla"
      debug_proc(@example)
      check_error_includes 'Invalid parameter blabla'
    end

    def test_info_line_shows_info_about_the_current_line
      enter 'break 11', 'cont', 'info line'
      debug_proc(@example)
      check_output_includes "Line 11 of \"#{__FILE__}\""
    end

    def test_info_program_shows_the_initial_stop_reason
      enter 'info program'
      debug_proc(@example)
      check_output_includes \
        "It stopped after stepping, next'ing or initial start."
    end

    def test_info_program_shows_the_step_stop_reason
      enter 'step', 'info program'
      debug_proc(@example)
      check_output_includes \
        'Program stopped.',
        "It stopped after stepping, next'ing or initial start."
    end

    def test_info_program_shows_the_breakpoint_stop_reason
      enter 'break 38', 'cont', 'info program'
      debug_proc(@example)
      check_output_includes 'Program stopped.', 'It stopped at a breakpoint.'
    end

    def test_info_program_shows_the_catchpoint_stop_reason
      enter 'catch Exception', 'cont', 'info program'
      debug_proc(@example)
      check_output_includes 'Program stopped.', 'It stopped at a catchpoint.'
    end

    def test_info_program_shows_the_unknown_stop_reason
      enter 'break 39', 'cont',
             ->{ context.stubs(:stop_reason).returns('blabla'); 'info program' }
      debug_proc(@example)
      check_output_includes 'Program stopped.', 'Unknown reason: blabla'
    end

    def test_shows_an_error_if_the_program_is_crashed
      skip('TODO')
    end

    def test_shows_help_when_typing_just_info
      enter 'info', 'cont'
      debug_proc(@example)
      check_output_includes(/List of "info" subcommands:/)
    end
  end
end
