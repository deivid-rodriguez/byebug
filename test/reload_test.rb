module Byebug
  class ReloadTestCase < TestCase
    def setup
      @example = -> do
        byebug
        a = 6
        a = 7
        a = 8
        a = 9
        a = 10
      end

      super
    end

    def test_reload_notifies_about_default_setting
      enter 'reload'
      debug_proc(@example)
      check_output_includes \
        'Source code was reloaded. Automatic reloading is on'
    end

    def test_reload_notifies_that_automatic_reloading_is_off_is_setting_changed
      enter 'set noautoreload', 'reload'
      debug_proc(@example)
      check_output_includes \
        'Source code was reloaded. Automatic reloading is off'
    end

    def test_reload_properly_reloads_source_code
      enter 'break 7', 'cont', 'l 8-8',
        -> { change_line_in_file(__FILE__, 8, '        a = 100'); 'reload' },
        'l 8-8'
      debug_proc(@example)
      check_output_includes '8:         a = 100'
      change_line_in_file(__FILE__, 8, '        a = 8')
    end
  end
end
