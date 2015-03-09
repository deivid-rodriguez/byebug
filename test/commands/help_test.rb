module Byebug
  #
  # Test command line help system.
  #
  class HelpTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    byebug
        3:
        4:    5
        5:  end
      EOC
    end

    def test_help_shows_help_for_help_command_itself
      with_setting :width, 50 do
        enter 'help'
        debug_code(program)

        expected_output = split_lines <<-TXT

          h[elp][ <cmd>[ <subcmd>]]

          help                -- prints this help.
          help <cmd>          -- prints help on command <cmd>.
          help <cmd> <subcmd> -- prints help on <cmd>'s subcommand <subcmd>.

        TXT

        check_output_includes(*expected_output)
      end
    end

    def test_help_with_specific_command_shows_help_for_it
      enter 'help break'
      debug_code(program)

      expected_output = split_lines <<-TXT
        b[reak] [file:]line [if expr]
        b[reak] [module::...]class(.|#)method [if expr]
        Set breakpoint to some position, (optionally) if expr == true
      TXT

      check_output_includes(*expected_output)
    end

    def test_help_with_undefined_command_shows_an_error
      enter 'help foobar'
      debug_code(program)
      check_error_includes 'Undefined command: foobar. Try: help'
    end

    def test_help_with_command_and_subcommand_shows_subcommands_help
      enter 'help info breakpoints'
      debug_code(program)
      check_output_includes(/Status of user-settable breakpoints/)
    end

    def test_help_set_shows_help_for_set_command
      enter 'help set'
      debug_code(program)
      check_output_includes(/Modifies parts of byebug environment/)
    end

    def test_help_set_plus_a_setting_shows_help_for_that_setting
      enter 'help set width'
      debug_code(program)
      check_output_includes(/Number of characters per line in byebug's output/)
    end

    def test_help_show_shows_help_for_show_command
      enter 'help show'
      debug_code(program)
      check_output_includes(/Generic command for showing byebug settings/)
    end
  end
end
