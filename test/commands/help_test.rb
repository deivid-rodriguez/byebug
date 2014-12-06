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

    %w(help h).each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_shows_help_for_help_command_itself") do
        enter 'set width 50', cmd_alias
        debug_code(program)

        (<<-TEXT
          h[elp][ <command>[ <subcommand>]]
          "help" alone prints this help.
          "help <command>" prints help on <command>.
          "help <command> <subcommand>" prints help on <subcommand>.
        TEXT
        ).split("\n").each do |line|
          check_output_includes line
        end
      end
    end

    def test_help_with_specific_command_shows_help_for_it
      enter 'help break'
      debug_code(program)

      (<<-TEXT
        b[reak] file:line [if expr]
        b[reak] class(.|#)method [if expr]
        Set breakpoint to some position, (optionally) if expr == true
      TEXT
      ).split("\n").each do |line|
        check_output_includes line
      end
    end

    def test_help_with_undefined_command_shows_an_error
      enter 'help foobar'
      debug_code(program)
      check_error_includes 'Undefined command: "foobar". Try "help"'
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
