require 'test_helper'

module Byebug
  #
  # Test command line help system.
  #
  class HelpTestCase < TestCase
    def test_help_shows_help_for_help_command_itself
      with_setting :width, 50 do
        enter 'help'
        debug_code(minimal_program)

        expected_output = split_lines <<-TXT

          h[elp][ <cmd>[ <subcmd>]]

          help                -- prints this help
          help <cmd>          -- prints help on command <cmd>
          help <cmd> <subcmd> -- prints help on <cmd>'s subcommand <subcmd>

        TXT

        check_output_includes(*expected_output)
      end
    end

    def test_help_with_specific_command_shows_help_for_it
      enter 'help break'
      debug_code(minimal_program)

      expected_output = split_lines <<-TXT
        b[reak] [file:]line [if expr]
        b[reak] [module::...]class(.|#)method [if expr]

        Sets breakpoints in the source code
      TXT

      check_output_includes(*expected_output)
    end

    def test_help_with_undefined_command_shows_an_error
      enter 'help foobar'
      debug_code(minimal_program)
      check_error_includes 'Undefined command: foobar. Try: help'
    end

    def test_help_with_command_and_subcommand_shows_subcommands_help
      enter 'help info breakpoints'
      debug_code(minimal_program)

      check_output_includes('Status of user settable breakpoints')
    end

    def test_help_set_shows_help_for_set_command
      enter 'help set'
      debug_code(minimal_program)
      check_output_includes('Modifies byebug settings')
    end

    def test_help_show_shows_help_for_show_command
      enter 'help show'
      debug_code(minimal_program)
      check_output_includes('Shows byebug settings')
    end
  end
end
