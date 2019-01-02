# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests help command without arguments
  #
  class HelpAloneTest < TestCase
    def setup
      super

      enter "help"
      debug_code(minimal_program)
    end

    {
      break: "Sets breakpoints in the source code",
      catch: "Handles exception catchpoints",
      condition: "Sets conditions on breakpoints",
      continue: "Runs until program ends, hits a breakpoint or reaches a line",
      delete: "Deletes breakpoints",
      disable: "Disables breakpoints or displays",
      display: "Evaluates expressions every time the debugger stops",
      down: "Moves to a lower frame in the stack trace",
      edit: "Edits source files",
      enable: "Enables breakpoints or displays",
      finish: "Runs the program until frame returns",
      frame: "Moves to a frame in the call stack",
      help: "Helps you using byebug",
      history: "Shows byebug's history of commands",
      info: "Shows several informations about the program being debugged",
      interrupt: "Interrupts the program",
      irb: "Starts an IRB session",
      kill: "Sends a signal to the current process",
      list: "Lists lines of source code",
      method: "Shows methods of an object, class or module",
      next: "Runs one or more lines of code",
      pry: "Starts a Pry session",
      quit: "Exits byebug",
      restart: "Restarts the debugged program",
      save: "Saves current byebug session to a file",
      set: "Modifies byebug settings",
      show: "Shows byebug settings",
      source: "Restores a previously saved byebug session",
      step: "Steps into blocks or methods one or more times",
      thread: "Commands to manipulate threads",
      tracevar: "Enables tracing of a global variable",
      undisplay: "Stops displaying all or some expressions when program stops",
      untrace: "Stops tracing a global variable",
      up: "Moves to a higher frame in the stack trace",
      variables: "Shows variables and its values",
      where: "Displays the backtrace"
    }.each do |command, description|
      define_method(:"test_shows_summary_for_#{command}_command") do
        check_output_includes(/#{description}/)
      end
    end
  end

  #
  # Tests help command with arguments
  #
  class HelpWithArgsTest < TestCase
    def test_help_help_shows_help_for_help_command_itself
      with_setting :width, 50 do
        enter "help help"
        debug_code(minimal_program)

        expected_output = split_lines <<-TXT

          h[elp][ <cmd>[ <subcmd>]]

          help                -- prints a summary of all commands
          help <cmd>          -- prints help on command <cmd>
          help <cmd> <subcmd> -- prints help on <cmd>'s subcommand <subcmd>

        TXT

        check_output_includes(*expected_output)
      end
    end

    def test_help_with_specific_command_shows_help_for_it
      enter "help break"
      debug_code(minimal_program)

      expected_output = split_lines <<-TXT
        b[reak] [<file>:]<line> [if <expr>]
        b[reak] [<module>::...]<class>(.|#)<method> [if <expr>]

        Sets breakpoints in the source code
      TXT

      check_output_includes(*expected_output)
    end

    def test_help_with_undefined_command_shows_an_error
      enter "help foobar"
      debug_code(minimal_program)

      check_error_includes "Unknown command 'foobar'. Try 'help'"
    end

    def test_help_with_undefined_subcommand_shows_an_error
      enter "help info foobar"
      debug_code(minimal_program)

      check_error_includes "Unknown command 'info foobar'. Try 'help info'"
    end

    def test_help_with_command_and_subcommand_shows_subcommands_help
      enter "help info breakpoints"
      debug_code(minimal_program)

      check_output_includes("Status of user settable breakpoints")
    end

    def test_help_set_shows_help_for_set_command_and_includes_settings
      enter "help set"
      debug_code(minimal_program)

      check_output_includes("Modifies byebug settings",
                            "List of supported settings:")
    end

    def test_help_show_shows_help_for_show_command_and_includes_settings
      enter "help show"
      debug_code(minimal_program)

      check_output_includes("Shows byebug settings",
                            "List of supported settings:")
    end
  end
end
