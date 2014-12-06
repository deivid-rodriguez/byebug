require 'byebug/runner'

module Byebug
  class RunnerTest < Minitest::Test
    include Byebug::TestUtils

    def setup
      Byebug.handler = Byebug::CommandProcessor.new(Byebug::TestInterface.new)

      @runner = Byebug::Runner.new
    end

    def test_run_with_version_flag
      with_command_line('bin/byebug', '--version') do
        @runner.run

        check_output_includes(/#{Byebug::VERSION}/)
      end
    end

    def test_run_with_help_flag
      with_command_line('bin/byebug', '--help') do
        @runner.run

        check_output_includes(
          /-d/, /-I/, /-q/, /-s/, /-x/, /-m/, /-r/, /-R/, /-t/, /-v/, /-h/)
      end
    end

    def test_run_with_remote_option_only_with_a_port_number
      with_command_line('bin/byebug', '--remote', '9999') do
        Byebug.expects(:start_client)
        @runner.run

        check_output_includes(/Connecting to byebug server localhost:9999/)
      end
    end

    def test_run_with_remote_option_with_host_and_port_specification
      with_command_line('bin/byebug', '--remote', 'myhost:9999') do
        Byebug.expects(:start_client)
        @runner.run

        check_output_includes(/Connecting to byebug server myhost:9999/)
      end
    end

    def test_run_without_a_script_to_debug
      with_command_line('bin/byebug') do
        assert_raises(SystemExit) { @runner.run }

        check_error_includes(/You must specify a program to debug.../)
      end
    end

    def test_run_with_an_nonexistent_script
      with_command_line('bin/byebug', 'non_existent_script.rb') do
        assert_raises(SystemExit) { @runner.run }

        check_error_includes("The script doesn't exist")
      end
    end

    def expect_it_debugs_script(rc = true)
      Byebug.expects(:start)
      rc_expectation = Byebug.expects(:run_init_script)
      rc_expectation.never unless rc
      @runner.expects(:debug_program)
    end

    def test_run_with_a_script_to_debug
      with_command_line('bin/byebug', 'lib/byebug.rb') do
        expect_it_debugs_script

        @runner.run
        assert_equal Byebug.debugged_program, File.expand_path('lib/byebug.rb')
      end
    end

    def test_run_with_a_script_and_params_does_not_consume_script_params
      with_command_line('bin/byebug', '--', 'lib/byebug.rb', '-opt', 'value') do
        expect_it_debugs_script

        @runner.run
        assert_equal %w(lib/byebug.rb -opt value), ARGV
      end
    end

    def test_run_with_ruby_script_ruby_is_ignored_and_script_passed_instead
      with_command_line('bin/byebug', '--', 'ruby', 'lib/byebug.rb') do
        expect_it_debugs_script

        @runner.run
        assert_equal Byebug.debugged_program, File.expand_path('lib/byebug.rb')
      end
    end

    def test_run_with_no_rc_option
      with_command_line('bin/byebug', '--no-rc', 'lib/byebug.rb') do
        expect_it_debugs_script(false)

        @runner.run
      end
    end

    def test_run_with_post_mortem_mode_flag
      with_command_line('bin/byebug', '--post-mortem', 'lib/byebug.rb') do
        expect_it_debugs_script
        @runner.run

        assert_equal true, Byebug.post_mortem?
        Byebug::Setting[:post_mortem] = false
      end
    end

    def test_run_with_linetracing_flag
      with_command_line('bin/byebug', '-t', 'lib/byebug.rb') do
        expect_it_debugs_script
        @runner.run

        assert_equal true, Byebug.tracing?
        Byebug::Setting[:linetrace] = false
      end
    end

    def test_run_with_no_quit_flag
      skip 'for now'
      with_command_line('bin/byebug', '--no-quit', 'lib/byebug.rb') do
        @runner.run

        check_output_includes('(byebug:ctrl)')
      end
    end

    def test_run_with_require_flag
      with_command_line('bin/byebug', '-r', 'abbrev', 'lib/byebug.rb') do
        expect_it_debugs_script
        @runner.run

        hsh = { 'can' => 'can', 'cat' => 'cat' }
        assert_equal hsh, %w(can cat).abbrev
      end
    end

    def test_run_with_include_flag
      with_command_line('bin/byebug', '-I', 'custom_dir', 'lib/byebug.rb') do
        expect_it_debugs_script
        @runner.run

        assert_includes $LOAD_PATH, 'custom_dir'
      end
    end

    def test_run_with_debug_flag
      with_command_line('bin/byebug', '-d', 'lib/byebug.rb') do
        expect_it_debugs_script
        @runner.run

        assert_equal $DEBUG, true
        $DEBUG = false
      end
    end
  end
end
