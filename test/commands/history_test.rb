# frozen_string_literal: true

require "test_helper"

unless ENV["LIBEDIT"]
  module Byebug
    #
    # Tests Byebug's command line history.
    #
    class HistoryTest < TestCase
      def program
        strip_line_numbers <<-RUBY
          1:  module Byebug
          2:    byebug
          3:
          4:    a = 2
          5:    a + 3
          6:  end
        RUBY
      end

      def test_history_displays_latest_records_from_readline_history
        enter "show", "history"
        debug_code(program)

        check_output_includes(/\d+  show$/, /\d+  history$/)
      end

      def test_history_n_displays_whole_history_if_n_is_bigger_than_history_size
        enter "show", "history 3"
        debug_code(program)

        check_output_includes(/\d+  show$/, /\d+  history 3$/)
      end

      def test_history_n_displays_lastest_n_records_from_readline_history
        enter "show width", "show autolist", "history 2"
        debug_code(program)

        check_output_includes(/\d+  show autolist$/, /\d+  history 2$/)
      end

      def test_history_does_not_save_empty_commands
        enter "show", "show width", "", "history 3"
        debug_code(program)

        check_output_includes(
          /\d+  show$/, /\d+  show width$/, /\d+  history 3$/
        )
      end

      def test_history_does_not_save_duplicated_consecutive_commands
        enter "show", "show width", "show width", "history 3"
        debug_code(program)

        check_output_includes(
          /\d+  show$/, /\d+  show width$/, /\d+  history 3$/
        )
      end

      def test_cmds_from_previous_repls_are_remembered_if_autosave_enabled
        with_setting :autosave, true do
          enter "next", "history 2"
          debug_code(program)

          check_output_includes(/\d+  next$/, /\d+  history 2$/)
        end
      end

      def test_cmds_from_previous_repls_are_not_remembered_if_autosave_disabled
        with_setting :autosave, false do
          enter "next", "history"
          debug_code(program)

          check_output_includes(/\d+  history$/)
          check_output_doesnt_include(/\d+  next$/)
        end
      end
    end
  end
end
