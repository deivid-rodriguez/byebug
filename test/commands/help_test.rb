require 'test_helper'

module Byebug
  #
  # Tests help command without arguments
  #
  class HelpAloneTest < TestCase
    def setup
      super

      enter 'help'
      debug_code(minimal_program)
    end

    def test_shows_summary_for_break_command
      check_output_includes(/Sets breakpoints in the source code/)
    end

    def test_shows_summary_for_catch_command
      check_output_includes(/Handles exception catchpoints/)
    end

    def test_shows_summary_for_condition_command
      check_output_includes(/Sets conditions on breakpoints/)
    end

    def test_shows_summary_for_continue_command
      check_output_includes(
        /Runs until program ends, hits a breakpoint or reaches a line/)
    end

    def test_shows_summary_for_delete_command
      check_output_includes(/Deletes breakpoints/)
    end

    def test_shows_summary_for_disable_command
      check_output_includes(/Disables breakpoints or displays/)
    end

    def test_shows_summary_for_display_command
      check_output_includes(
        /Evaluates expressions every time the debugger stops/)
    end

    def test_shows_summary_for_down_command
      check_output_includes(/Moves to a lower frame in the stack trace/)
    end

    def test_shows_summary_for_edit_command
      check_output_includes(/Edits source files/)
    end

    def test_shows_summary_for_enable_command
      check_output_includes(/Enables breakpoints or displays/)
    end

    def test_shows_summary_for_finish_command
      check_output_includes(/Runs the program until frame returns/)
    end

    def test_shows_summary_for_frame_command
      check_output_includes(/Moves to a frame in the call stack/)
    end

    def test_shows_summary_for_help_command
      check_output_includes(/Helps you using byebug/)
    end

    def test_shows_summary_for_history_command
      check_output_includes(/Shows byebug's history of commands/)
    end

    def test_shows_summary_for_info_command
      check_output_includes(
        /Shows several informations about the program being debugged/)
    end

    def test_shows_summary_for_interrupt_command
      check_output_includes(/Interrupts the program/)
    end

    def test_shows_summary_for_irb_command
      check_output_includes(/Starts an IRB session/)
    end

    def test_shows_summary_for_kill_command
      check_output_includes(/Sends a signal to the current process/)
    end

    def test_shows_summary_for_list_command
      check_output_includes(/Lists lines of source code/)
    end

    def test_shows_summary_for_method_command
      check_output_includes(/Shows methods of an object, class or module/)
    end

    def test_shows_summary_for_next_command
      check_output_includes(/Runs one or more lines of code/)
    end

    def test_shows_summary_for_pry_command
      check_output_includes(/Starts a Pry session/)
    end

    def test_shows_summary_for_quit_command
      check_output_includes(/Exits byebug/)
    end

    def test_shows_summary_for_restart_command
      check_output_includes(/Restarts the debugged program/)
    end

    def test_shows_summary_for_save_command
      check_output_includes(/Saves current byebug session to a file/)
    end

    def test_shows_summary_for_set_command
      check_output_includes(/Modifies byebug settings/)
    end

    def test_shows_summary_for_show_command
      check_output_includes(/Shows byebug settings/)
    end

    def test_shows_summary_for_source_command
      check_output_includes(/Restores a previously saved byebug session/)
    end

    def test_shows_summary_for_step_command
      check_output_includes(/Steps into blocks or methods one or more times/)
    end

    def test_shows_summary_for_thread_command
      check_output_includes(/Commands to manipulate threads/)
    end

    def test_shows_summary_for_tracevar_command
      check_output_includes(/Enables tracing of a global variable/)
    end

    def test_shows_summary_for_undisplay_command
      check_output_includes(
        /Stops displaying all or some expressions when program stops/)
    end

    def test_shows_summary_for_untrace_command
      check_output_includes(/Stops tracing a global variable/)
    end

    def test_shows_summary_for_up_command
      check_output_includes(/Moves to a higher frame in the stack trace/)
    end

    def test_shows_summary_for_var_command
      check_output_includes(/Shows variables and its values/)
    end

    def test_shows_summary_for_where_command
      check_output_includes(/Displays the backtrace/)
    end
  end

  #
  # Tests help command with arguments
  #
  class HelpWithArgsTest < TestCase
    def test_help_help_shows_help_for_help_command_itself
      with_setting :width, 50 do
        enter 'help help'
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

      check_error_includes "Unknown command 'foobar'. Try 'help'"
    end

    def test_help_with_undefined_subcommand_shows_an_error
      enter 'help info foobar'
      debug_code(minimal_program)

      check_error_includes "Unknown command 'info foobar'. Try 'help info'"
    end

    def test_help_with_command_and_subcommand_shows_subcommands_help
      enter 'help info breakpoints'
      debug_code(minimal_program)

      check_output_includes('Status of user settable breakpoints')
    end

    def test_help_set_shows_help_for_set_command_and_includes_settings
      enter 'help set'
      debug_code(minimal_program)

      check_output_includes('Modifies byebug settings',
                            'List of supported settings:')
    end

    def test_help_show_shows_help_for_show_command_and_includes_settings
      enter 'help show'
      debug_code(minimal_program)

      check_output_includes('Shows byebug settings',
                            'List of supported settings:')
    end
  end
end
