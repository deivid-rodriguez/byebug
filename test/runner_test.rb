require 'byebug/runner'

module Byebug
  class RunnerTest < TestCase
    def setup
      super
      @old_argv = ARGV
      @runner = Byebug::Runner.new
    end

    def after
      ARGV.replace(@old_argv)
    end

    def test_run_with_version_flag
      ARGV.replace(%w(--version))
      @runner.run

      check_output_includes(/#{Byebug::VERSION}/)
    end

    def test_run_with_help_flag
      ARGV.replace(%w(--help))
      @runner.run

      check_output_includes(/-d.*-I.*-q.*-s.*-x.*-m.*-r.*-R.*-t.*-v.*-h/m)
    end

    def test_run_with_remote_option_only_with_a_port_number
      ARGV.replace(%w(--remote 9999))
      Byebug.expects(:start_client)
      @runner.run

      check_output_includes(/Connecting to byebug server localhost:9999/)
    end

    def test_run_with_remote_option_with_host_and_port_specification
      ARGV.replace(%w(--remote myhost:9999))
      Byebug.expects(:start_client)
      @runner.run

      check_output_includes(/Connecting to byebug server myhost:9999/)
    end

    def test_run_without_a_script_to_debug
      ARGV.replace([])

      assert_raises(SystemExit) { @runner.run }

      check_error_includes(/You must specify a program to debug.../)
    end

    def test_run_with_an_nonexistent_script
      ARGV.replace(%w(non_existent_script.rb))

      assert_raises(SystemExit) { @runner.run }

      check_error_includes("The script doesn't exist")
    end

    def expect_it_debugs_script(rc = true)
      Byebug.expects(:start)
      rc_expectation = Byebug.expects(:run_init_script)
      rc_expectation.never unless rc
      @runner.expects(:debug_program)
    end

    def test_run_with_a_script_to_debug
      ARGV.replace(%w(lib/byebug.rb))
      expect_it_debugs_script

      @runner.run
    end

    def test_run_with_a_script_and_params_does_not_consume_script_params
      ARGV.replace(%w(-- lib/byebug.rb -opt value))
      expect_it_debugs_script

      @runner.run
      assert_equal %w(lib/byebug.rb -opt value), ARGV
    end

    def test_run_with_ruby_script_ruby_is_ignored_and_script_passed_instead
      ARGV.replace(%w(-- ruby lib/byebug.rb))
      expect_it_debugs_script

      @runner.run
      assert_equal %w(lib/byebug.rb), ARGV
    end

    def test_run_with_no_rc_option
      ARGV.replace(%w(--no-rc lib/byebug.rb))
      expect_it_debugs_script(false)

      @runner.run
    end

    def test_run_with_post_mortem_mode_flag
      ARGV.replace(%w(-m lib/byebug.rb))
      expect_it_debugs_script
      @runner.run

      assert_equal true, Byebug.post_mortem?
      Byebug::Setting[:post_mortem] = false
    end

    def test_run_with_linetracing_flag
      ARGV.replace(%w(-t lib/byebug.rb))
      expect_it_debugs_script
      @runner.run

      assert_equal true, Byebug.tracing?
      Byebug::Setting[:linetrace] = false
    end

    def test_run_with_no_quit_flag
      skip 'for now'
      ARGV.replace(%w(--no-quit lib/byebug.rb))
      @runner.run

      check_output_includes('(byebug:ctrl)')
    end

    def test_run_with_require_flag
      ARGV.replace(%w(-r abbrev lib/byebug.rb))
      expect_it_debugs_script
      @runner.run

      hsh = { 'can' => 'can', 'cat' => 'cat' }
      assert_equal hsh, %w(can cat).abbrev
    end

    def test_run_with_include_flag
      ARGV.replace(%w(-I custom_dir lib/byebug.rb))
      expect_it_debugs_script
      @runner.run

      assert_includes $LOAD_PATH, 'custom_dir'
    end

    def test_run_with_debug_flag
      ARGV.replace(%w(-d lib/byebug.rb))
      expect_it_debugs_script
      @runner.run

      assert_equal $DEBUG, true
      $DEBUG = false
    end
  end
end
