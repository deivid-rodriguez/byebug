module Byebug
  #
  # Tests for "reload" command
  #
  class ReloadTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  module Byebug
        2:    #
        3:    # Toy class to test code reloading
        4:    #
        5:    class TestExample
        6:      byebug
        7:    end
        8:  end
      EOC
    end

    def test_reload_notifies_about_default_setting
      enter 'reload'
      debug_code(program)
      check_output_includes \
        'Source code was reloaded. Automatic reloading is on'
    end

    def test_reload_notifies_that_automatic_reloading_is_off_is_setting_changed
      enter 'set noautoreload', 'reload'
      debug_code(program)
      check_output_includes \
        'Source code was reloaded. Automatic reloading is off'
    end

    def test_reload_properly_reloads_source_code
      enter \
        'l 3-3',
        -> { cmd_after_replace(example_path, 3, '# New comment', 'reload') },
        'l 3-3'

      debug_code(program)
      check_output_includes(/3:\s+# New comment/)
    end
  end
end
