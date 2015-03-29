require 'byebug/runner'

module Byebug
  class RunnerTest < TestCase
    def setup
      super

      @runner = Byebug::Runner.new(false)
    end

    def test_run_with_version_flag
      with_command_line('bin/byebug', '--version') { @runner.run }

      check_output_includes(/#{Byebug::VERSION}/)
    end

    def test_run_with_help_flag
      with_command_line('bin/byebug', '--help') { @runner.run }

      check_output_includes(
        /-d/, /-I/, /-q/, /-s/, /-x/, /-m/, /-r/, /-R/, /-t/, /-v/, /-h/)
    end

    def test_run_with_remote_option_only_with_a_port_number
      Byebug.expects(:start_client)

      with_command_line('bin/byebug', '--remote', '9999') { @runner.run }
    end

    def test_run_with_remote_option_with_host_and_port_specification
      Byebug.expects(:start_client)

      with_command_line('bin/byebug', '--remote', 'myhost:9999') { @runner.run }
    end

    def test_run_without_a_script_to_debug
      with_command_line('bin/byebug') do
        assert_raises(Runner::NoScript) { @runner.run }
      end
    end

    def test_run_with_an_nonexistent_script
      with_command_line('bin/byebug', 'non_existent_script.rb') do
        assert_raises(Runner::NonExistentScript) { @runner.run }
      end
    end

    def test_run_with_a_script_to_debug
      @runner.expects(:debug_program)

      with_command_line('bin/byebug', example_path) do
        @runner.run

        assert_equal $PROGRAM_NAME, example_path
      end
    end

    def test_run_with_a_script_and_params_does_not_consume_script_params
      @runner.expects(:debug_program)

      with_command_line('bin/byebug', '--', example_path, '-opt', 'value') do
        @runner.run

        assert_equal ['-opt', 'value'], $ARGV
      end
    end

    def test_run_with_ruby_script_ruby_is_ignored_and_script_passed_instead
      @runner.expects(:debug_program)

      with_command_line('bin/byebug', '--', 'ruby', example_path) do
        @runner.run

        assert_equal example_path, $PROGRAM_NAME
      end
    end

    def test_run_with_no_rc_option
      @runner.expects(:debug_program)
      Byebug.expects(:run_init_script).never

      with_command_line('bin/byebug', '--no-rc', example_path) { @runner.run }
    end

    def test_run_with_post_mortem_mode_flag
      @runner.expects(:debug_program)

      with_setting :post_mortem, false do
        with_command_line('bin/byebug', '-m', example_path) do
          @runner.run
          assert_equal true, Setting[:post_mortem]
        end
      end
    end

    def test_run_with_linetracing_flag
      @runner.expects(:debug_program)

      with_setting :linetrace, false do
        with_command_line('bin/byebug', '-t', example_path) do
          @runner.run
          assert_equal true, Setting[:linetrace]
        end
      end
    end

    def test_run_with_no_quit_flag
      skip('TODO')
      @runner.expects(:debug_program)
      with_command_line('bin/byebug', '--no-quit', example_path) do
        @runner.run

        check_output_includes('(byebug:ctrl)')
      end
    end

    def test_run_with_require_flag
      @runner.expects(:debug_program)

      with_command_line('bin/byebug', '-r', 'abbrev', example_path) do
        @runner.run
      end

      hsh = { 'can' => 'can', 'cat' => 'cat' }
      assert_equal hsh, %w(can cat).abbrev
    end

    def test_run_with_a_single_include_flag
      @runner.expects(:debug_program)

      with_command_line('bin/byebug', '-I', 'dir1', example_path) do
        @runner.run
      end

      assert_includes $LOAD_PATH, 'dir1'
    end

    def test_run_with_several_include_flags
      @runner.expects(:debug_program)

      with_command_line('bin/byebug', '-I', 'dir1:dir2', example_path) do
        @runner.run
      end

      assert_includes $LOAD_PATH, 'dir1'
      assert_includes $LOAD_PATH, 'dir2'
    end

    def test_run_with_debug_flag
      @runner.expects(:debug_program)

      with_command_line('bin/byebug', '-d', example_path) { @runner.run }

      assert_equal $DEBUG, true
      $DEBUG = false
    end

    def test_run_with_script_with_wrong_syntax
      example_file.write('[1,2,')
      example_file.close

      with_command_line('bin/byebug', example_path) do
        assert_raises(SystemExit) { @runner.run }
      end

      check_error_includes(/syntax error, unexpected end-of-input/)
    end

    def test_run_successfully
      example_file.write('sleep 0')
      example_file.close

      with_command_line('bin/byebug', example_path) { @runner.run }

      assert_empty interface.output
    end
  end
end
