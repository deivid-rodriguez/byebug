require 'test_helper'
require 'byebug/runner'

module Byebug
  #
  # Tests standalone byebug when flags that require no target program are used
  #
  class RunnerWithoutTargetProgramTest < TestCase
    def setup
      super

      runner.interface = Context.interface
    end

    def test_run_with_version_flag
      with_command_line('bin/byebug', '--version') { runner.run }

      check_output_includes(/#{Byebug::VERSION}/)
    end

    def test_run_with_help_flag
      with_command_line('bin/byebug', '--help') { runner.run }

      check_output_includes(
        /-d/, /-I/, /-q/, /-s/, /-x/, /-m/, /-r/, /-R/, /-t/, /-v/, /-h/
      )
    end

    def test_run_with_remote_option_only_with_a_port_number
      with_command_line('bin/byebug', '--remote', '9999') do
        assert_calls(Byebug, :start_client, 'localhost 9999') { runner.run }
      end
    end

    def test_run_with_remote_option_with_host_and_port_specification
      with_command_line('bin/byebug', '--remote', 'myhost:9999') do
        assert_calls(Byebug, :start_client, 'myhost 9999') { runner.run }
      end
    end

    def test_run_without_a_script_to_debug
      with_command_line('bin/byebug') do
        runner.run

        check_error_includes 'You must specify a program to debug'
      end
    end

    def test_run_with_an_nonexistent_script
      with_command_line('bin/byebug', 'non_existent_script.rb') do
        runner.run

        check_error_includes "The script doesn't exist"
      end
    end

    def test_run_with_an_invalid_script
      example_file.write('[1,2,')
      example_file.close

      with_command_line('bin/byebug', example_path) do
        runner.run

        check_error_includes 'The script has incorrect syntax'
      end
    end

    private

    def runner
      @runner ||= Byebug::Runner.new(false)
    end
  end

  #
  # Tests standalone byebug when debugging a target program
  #
  class RunnerAgainstValidProgramTest < TestCase
    def setup
      super

      example_file.write('sleep 0')
      example_file.close
    end

    def test_run_with_a_script_to_debug
      with_command_line('bin/byebug', example_path) do
        non_stop_runner.run

        assert_equal $PROGRAM_NAME, example_path
      end
    end

    def test_run_with_a_script_and_params_does_not_consume_script_params
      with_command_line('bin/byebug', '--', example_path, '-opt', 'value') do
        non_stop_runner.run

        assert_equal ['-opt', 'value'], $ARGV
      end
    end

    def test_run_with_ruby_script_ruby_is_ignored_and_script_passed_instead
      with_command_line('bin/byebug', '--', 'ruby', example_path) do
        non_stop_runner.run

        assert_equal example_path, $PROGRAM_NAME
      end
    end

    def test_run_with_post_mortem_mode_flag
      with_setting :post_mortem, false do
        with_command_line('bin/byebug', '-m', example_path) do
          non_stop_runner.run

          assert_equal true, Setting[:post_mortem]
        end
      end
    end

    def test_run_with_linetracing_flag
      with_setting :linetrace, false do
        with_command_line('bin/byebug', '-t', example_path) do
          non_stop_runner.run

          assert_equal true, Setting[:linetrace]
        end
      end
    end

    def test_run_with_no_quit_flag
      skip

      with_command_line('bin/byebug', '--no-quit', example_path) do
        non_stop_runner.run

        check_output_includes('(byebug:ctrl)')
      end
    end

    def test_run_with_require_flag
      with_command_line('bin/byebug', '-r', 'abbrev', example_path) do
        non_stop_runner.run
      end

      hsh = { 'can' => 'can', 'cat' => 'cat' }
      assert_equal hsh, %w(can cat).abbrev
    end

    def test_run_with_a_single_include_flag
      with_command_line('bin/byebug', '-I', 'dir1', example_path) do
        non_stop_runner.run
      end

      assert_includes $LOAD_PATH, 'dir1'
    end

    def test_run_with_several_include_flags
      with_command_line('bin/byebug', '-I', 'dir1:dir2', example_path) do
        non_stop_runner.run
      end

      assert_includes $LOAD_PATH, 'dir1'
      assert_includes $LOAD_PATH, 'dir2'
    end

    def test_run_with_debug_flag
      with_command_line('bin/byebug', '-d', example_path) do
        non_stop_runner.run
      end

      assert_equal $DEBUG, true
      $DEBUG = false
    end

    def test_run_stops_at_the_first_line_by_default
      skip('Next is 12 not 20 on Ruby 2.2.3') if RUBY_VERSION == '2.2.3'
      enter 'cont'
      with_command_line('bin/byebug', example_path) { stop_first_runner.run }

      check_output_includes '=> 1: sleep 0'
    end

    def test_run_with_no_stop_flag_does_not_stop_at_the_first_line
      non_stop_runner.interface = Context.interface

      with_command_line('bin/byebug --no-stop', example_path) do
        non_stop_runner.run
      end

      assert_empty non_stop_runner.interface.output
    end

    def test_run_with_stop_flag_stops_at_the_first_line
      skip('Next is 12 not 20 on Ruby 2.2.3') if RUBY_VERSION == '2.2.3'
      enter 'cont'

      with_command_line('bin/byebug --stop', example_path) do
        stop_first_runner.run
      end

      check_output_includes '=> 1: sleep 0'
    end

    private

    def non_stop_runner
      @non_stop_runner ||= Byebug::Runner.new(false)
    end

    def stop_first_runner
      @stop_first_runner ||= Byebug::Runner.new(true)
    end
  end
end
