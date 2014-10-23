require 'byebug/runner'
require 'minitest/mock'

module Byebug
  class RemoteInterfaceTest < TestCase
    def setup
      super

      @old_argv = ARGV
      @remote_socket_mock = Minitest::Mock.new
      @remote_interface = Byebug::RemoteInterface.new(@remote_socket_mock)
    end

    def teardown
      ARGV.replace(@old_argv)
    end

    class ReadCommandTest < RemoteInterfaceTest
      def test_read_command_prints_to_output
        @remote_socket_mock.expect(:puts, nil, ['PROMPT test_command'])
        @remote_socket_mock.stub(:gets, '') do
          @remote_interface.read_command('test_command')
        end
        @remote_socket_mock.verify
      end

      def test_read_command_records_history_of_user_input
        @history_mock = Minitest::Mock.new
        @history_mock.expect(:push, nil, ['foo'])
        @remote_interface.history = @history_mock

        @remote_socket_mock.stub(:gets, 'foo') do
          @remote_socket_mock.stub(:puts, nil) do
            @remote_interface.read_command('test_command')
          end
        end
        @history_mock.verify
      end

      def test_read_command_returns_input_with_trailing_whitespace_stripped
        @remote_socket_mock.stub(:puts, nil) do
          @remote_socket_mock.stub(:gets, "foo\r\n") do
            result = @remote_interface.read_command('test_command')

            assert_equal(result, 'foo')
          end
        end
      end

      def test_read_command_with_no_input_raises_io_error
        @remote_socket_mock.stub(:puts, nil) do
          @remote_socket_mock.stub(:gets, nil) do
            assert_raises(IOError) do
              @remote_interface.read_command('test_command')
            end
            @remote_socket_mock.verify
          end
        end
      end
    end

    class CloseTest < RemoteInterfaceTest
      def test_close_calls_close_on_the_output_socket
        @remote_socket_mock.expect(:close, nil)

        @remote_interface.close
        @remote_socket_mock.verify
      end

      def test_close_with_error_calls_print_on_error_socket
        def @remote_socket_mock.close
          fail IOError
        end

        @remote_socket_mock.expect(:print, nil,
                                   ["*** Error closing the interface...\n"])

        @remote_interface.close
        @remote_socket_mock.verify
      end
    end

    class ConfirmTest < RemoteInterfaceTest
      def test_confirm_prompts_for_input_with_confirm
        @remote_socket_mock.expect(:puts, nil, ['CONFIRM test_command'])
        @remote_socket_mock.stub(:gets, 'y') do
          @remote_interface.confirm('test_command')
        end
        @remote_socket_mock.verify
      end

      def test_confirm_does_not_log_history
        fail_on_push = lambda do |pushed_message|
          flunk('history should not be called, was called with' +
                pushed_message)
        end
        @remote_socket_mock.stub(:puts, nil) do
          @remote_socket_mock.stub(:gets, 'y') do
            @remote_interface.history.stub(:push, fail_on_push) do
              @remote_interface.confirm('test_command')
            end
          end
        end
        @remote_socket_mock.verify
      end

      def test_confirm_returns_true_when_user_enters_y
        @remote_socket_mock.stub(:puts, nil) do
          @remote_socket_mock.stub(:gets, 'y') do
            result = @remote_interface.confirm('test_command')
            assert_equal(result, true)
          end
        end
      end

      def test_confirm_returns_false_when_user_does_not_enter_y
        @remote_socket_mock.stub(:puts, nil) do
          @remote_socket_mock.stub(:gets, 'not y') do
            result = @remote_interface.confirm('test_command')
            assert_equal(result, false)
          end
        end
      end
    end
  end
end
