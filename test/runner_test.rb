require 'byebug/runner'

module Byebug

  class RunnerTest < TestCase
    def setup
      super
      @old_argv = ARGV
    end

    def after
      ARGV.replace(@old_argv)
    end

    def test_run_with_version_flag
      ARGV.replace(%w(--version))
      Byebug::Runner.new.run

      check_output_includes(/#{Byebug::VERSION}/)
    end

    def test_run_with_help_flag
      ARGV.replace(%w(--help))
      Byebug::Runner.new.run

      check_output_includes(/-d.*-I.*-q.*-s.*-x.*-m.*-r.*-R.*-t.*-v.*-h/m)
    end

    def test_run_with_remote_option_only_with_a_port_number
      ARGV.replace(%w(--remote 9999))
      Byebug.expects(:start_client)
      Byebug::Runner.new.run

      check_output_includes(/Connecting to byebug server localhost:9999/)
    end

    def test_run_with_remote_option_with_host_and_port_specification
      ARGV.replace(%w(--remote myhost:9999))
      Byebug.expects(:start_client)
      Byebug::Runner.new.run

      check_output_includes(/Connecting to byebug server myhost:9999/)
    end

    def test_run_without_a_script_to_debug
      ARGV.replace([])

      assert_raises(SystemExit) { Byebug::Runner.new.run }

      check_output_includes(/You must specify a program to debug.../)
    end

    def expect_it_debugs_script
      Byebug.expects(:start)
      Byebug::Runner.any_instance.expects(:debug_program)
      Byebug.expects(:run_init_script)
    end

    def test_run_with_a_script_to_debug
      ARGV.replace(%w(my_script))
      expect_it_debugs_script

      Byebug::Runner.new.run
    end

    def test_run_with_no_rc_option
      ARGV.replace(%w(--no-rc my_script))
      Byebug.expects(:start)
      Byebug::Runner.any_instance.expects(:debug_program)
      Byebug.expects(:run_init_script).never

      Byebug::Runner.new.run
    end

    def test_run_with_post_mortem_mode_flag
      ARGV.replace(%w(-m my_script))
      expect_it_debugs_script

      Byebug::Runner.new.run
      assert_equal true, Byebug.post_mortem?
      Byebug::Setting[:post_mortem] = false
    end

    def test_run_with_linetracing_flag
      ARGV.replace(%w(-t my_script))
      expect_it_debugs_script

      Byebug::Runner.new.run
      assert_equal true, Byebug.tracing?
      Byebug::Setting[:linetrace] = false
    end

    def test_run_with_no_quit_flag
      skip 'for now'
      ARGV.replace(%w(--no-quit my_script))

      Byebug::Runner.new.run
      check_output_includes('(byebug:ctrl)')
    end

    def test_run_with_require_flag
      ARGV.replace(%w(-r abbrev my_script))
      expect_it_debugs_script

      Byebug::Runner.new.run
      hsh = { 'can' => 'can', 'cat' => 'cat' }
      assert_equal hsh, %w(can cat).abbrev
    end

    def test_run_with_include_flag
      ARGV.replace(%w(-I custom_dir my_script))
      expect_it_debugs_script

      Byebug::Runner.new.run
      assert_includes $LOAD_PATH, 'custom_dir'
    end

    def test_run_with_debug_flag
      ARGV.replace(%w(-d my_script))
      expect_it_debugs_script

      Byebug::Runner.new.run
      assert_equal $DEBUG, true
      $DEBUG = false
    end
  end
end
