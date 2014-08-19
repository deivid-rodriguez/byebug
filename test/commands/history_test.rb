module Byebug
  class HistoryTestCase < TestCase
    def setup
      @example = -> do
        byebug
      end

      super

      @old_readline = Readline::HISTORY
      force_set_const(Readline, 'HISTORY', %w(aaa bbb ccc ddd))
    end

    def teardown
      force_set_const(Readline, 'HISTORY', @old_readline)
    end

    def test_history_displays_latest_records_from_readline_history
      enter 'set histsize 3', 'history'
      debug_proc(@example)
      check_output_includes(/2  bbb\n    3  ccc\n    4  ddd/)
      check_output_doesnt_include(/1  aaa/)
    end

    def test_history_displays_whole_history_if_max_size_is_bigger_than_readline
      enter 'set histsize 7', 'history'
      debug_proc(@example)
      check_output_includes(/1  aaa\n    2  bbb\n    3  ccc\n    4  ddd/)
    end

    def test_history_n_displays_lastest_n_records_from_readline_history
      enter 'history 2'
      debug_proc(@example)
      check_output_includes(/3  ccc\n    4  ddd/)
      check_output_doesnt_include(/1  aaa\n    2  bbb/)
    end

    def test_history_with_autosave_disabled_does_not_show_records_from_readline
      enter 'set noautosave', 'history'
      debug_proc(@example)
      check_error_includes "Not currently saving history. " \
                           'Enable it with "set autosave"'
    end
  end
end
