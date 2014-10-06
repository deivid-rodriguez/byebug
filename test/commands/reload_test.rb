module Byebug
  #
  # Tests for "reload" command
  #
  class ReloadTestCase < TestCase
    def setup
      @example = lambda do
        byebug
        a = 9
        a += 10
        a += 11
        a += 12
        a += 13
        a + 14
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

    def reload_after_change(file, line, content)
      change_line(file, line, content)
      'reload'
    end

    def test_reload_properly_reloads_source_code
      enter 'l 10-10',
            -> { reload_after_change(__FILE__, 10, '        a += 100') },
            'l 10-10'
      debug_proc(@example)
      check_output_includes '10:         a += 100'
    ensure
      change_line(__FILE__, 10, '        a += 10')
    end
  end
end
