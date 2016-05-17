require 'test_helper'
require 'byebug/runner'

module Byebug
  class RcTest < TestCase
    def setup
      super

      example_file.write('sleep 0')
      example_file.close
    end

    def test_run_with_no_rc_option
      with_command_line('bin/byebug', '--no-rc', example_path) do
        refute_calls(Byebug, :run_init_script) { non_stop_runner.run }
      end
    end

    def test_rc_file_commands_are_properly_run_by_default
      rc_positive_test(nil)
    end

    def test_rc_file_commands_are_properly_run_by_explicit_option
      rc_positive_test('--rc')
    end

    private

    def rc_positive_test(flag)
      args = [flag, example_path].compact

      with_setting :callstyle, 'short' do
        with_init_file('set callstyle long') do
          with_command_line('bin/byebug', *args) do
            non_stop_runner.run

            assert_equal 'long', Setting[:callstyle]
          end
        end
      end
    end

    def non_stop_runner
      @non_stop_runner ||= Byebug::Runner.new(false)
    end
  end
end
