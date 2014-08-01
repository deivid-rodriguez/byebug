module Byebug
  class HelpTestCase < TestCase
    include Columnize

    def setup
      @example = -> do
        byebug
      end

      super
    end

    def available_cmds
      @available_cmds ||=
        Command.commands.map(&:names).flatten.uniq.sort
    end

    %w(help h).each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_shows_help_for_help_command_itself") do
        enter 'set width 50', cmd_alias
        debug_proc(@example)
        check_output_includes \
          'Type "help <command-name>" for help on a specific command',
          'Available commands:', columnize(available_cmds, 50)
      end
    end

    def test_help_with_specific_command_shows_help_for_it
      enter 'help break'
      debug_proc(@example)
      check_output_includes \
        "b[reak] file:line [if expr]\n" \
        "b[reak] class(.|#)method [if expr]\n\n" \
        "Set breakpoint to some position, (optionally) if expr == true\n"
    end

    def test_help_with_undefined_command_shows_an_error
      enter 'help foobar'
      debug_proc(@example)
      check_error_includes 'Undefined command: "foobar". Try "help".'
    end

    def test_help_with_command_and_subcommand_shows_subcommands_help
      enter 'help info breakpoints'
      debug_proc(@example)
      check_output_includes "Status of user-settable breakpoints.\n"
    end
  end
end
