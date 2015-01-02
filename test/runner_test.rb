require 'byebug/runner'

module Byebug
  class RunnerTest < TestCase
    def setup
      super

      @runner = Byebug::Runner.new(false)
    end

    def test_run_with_version_flag
      with_command_line('bin/byebug', '--version') do
        assert_raises(SystemExit) { @runner.run }

        check_output_includes(/#{Byebug::VERSION}/)
      end
    end

    def test_run_with_help_flag
      with_command_line('bin/byebug', '--help') do
        assert_raises(SystemExit) { @runner.run }

        check_output_includes(
          /-d/, /-I/, /-q/, /-s/, /-x/, /-m/, /-r/, /-R/, /-t/, /-v/, /-h/)
      end
    end

    def test_run_with_remote_option_only_with_a_port_number
      with_command_line('bin/byebug', '--remote', '9999') do
        Byebug.expects(:start_client)
        assert_raises(SystemExit) { @runner.run }
      end
    end

    def test_run_with_remote_option_with_host_and_port_specification
      with_command_line('bin/byebug', '--remote', 'myhost:9999') do
        Byebug.expects(:start_client)
        assert_raises(SystemExit) { @runner.run }
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

    def setup_dummy_script
      example_file.write('sleep 0')
      example_file.close
    end

    def test_run_with_a_script_to_debug
      setup_dummy_script

      with_command_line('bin/byebug', example_path) do
        @runner.run

        assert_equal Byebug.debugged_program, example_path
      end
    end

    def test_run_with_a_script_and_params_does_not_consume_script_params
      setup_dummy_script

      with_command_line('bin/byebug', '--', example_path, '-opt', 'value') do
        @runner.run

        assert_equal [example_path, '-opt', 'value'], ARGV
      end
    end

    def test_run_with_ruby_script_ruby_is_ignored_and_script_passed_instead
      setup_dummy_script

      with_command_line('bin/byebug', '--', 'ruby', example_path) do
        @runner.run

        assert_equal Byebug.debugged_program, example_path
      end
    end

    def test_run_with_no_rc_option
      setup_dummy_script

      with_command_line('bin/byebug', '--no-rc', example_path) do
        Byebug.expects(:run_init_script).never

        @runner.run
      end
    end

    def test_run_with_post_mortem_mode_flag
      setup_dummy_script

      with_command_line('bin/byebug', '--post-mortem', example_path) do
        Setting.expects(:[]=).with(:post_mortem, true)

        @runner.run
      end
    end

    def test_run_with_linetracing_flag
      setup_dummy_script

      with_command_line('bin/byebug', '-t', example_path) do
        Setting.expects(:[]=).with(:linetrace, true)

        @runner.run
      end
    end

    def test_run_with_no_quit_flag
      skip('TODO')
      setup_dummy_script

      with_command_line('bin/byebug', '--no-quit', example_path) do
        @runner.run

        check_output_includes('(byebug:ctrl)')
      end
    end

    def test_run_with_require_flag
      setup_dummy_script

      with_command_line('bin/byebug', '-r', 'abbrev', example_path) do
        @runner.run

        hsh = { 'can' => 'can', 'cat' => 'cat' }
        assert_equal hsh, %w(can cat).abbrev
      end
    end

    def test_run_with_a_single_include_flag
      setup_dummy_script

      with_command_line('bin/byebug', '-I', 'dir1', example_path) do
        @runner.run

        assert_includes $LOAD_PATH, 'dir1'
      end
    end

    def test_run_with_several_include_flags
      setup_dummy_script

      with_command_line('bin/byebug', '-I', 'dir1:dir2', example_path) do
        @runner.run

        assert_includes $LOAD_PATH, 'dir1'
        assert_includes $LOAD_PATH, 'dir2'
      end
    end

    def test_run_with_debug_flag
      setup_dummy_script

      with_command_line('bin/byebug', '-d', example_path) do
        @runner.run

        assert_equal $DEBUG, true
        $DEBUG = false
      end
    end
  end
end
