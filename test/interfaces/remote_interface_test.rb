require 'byebug/runner'
require 'mocha/mini_test'

module Byebug
  class RemoteInterfaceTest < Minitest::Test
    def setup
      @old_argv = $ARGV
      @remote_socket_mock = mock('remote socket')
      @remote_interface = Byebug::RemoteInterface.new(@remote_socket_mock)
    end

    def teardown
      $ARGV.replace(@old_argv)
    end

    class ReadCommandTest < RemoteInterfaceTest
      def test_read_command_prints_to_output
        @remote_socket_mock.expects(:puts).with('PROMPT test_command')
        @remote_socket_mock.stubs(:gets).returns('')

        @remote_interface.read_command('test_command')
      end

      def test_read_command_records_history_of_user_input
        @history_mock = mock('history')
        @history_mock.expects(:push).with('foo')
        @remote_interface.history = @history_mock
        @remote_socket_mock.stubs(:gets).returns('foo')
        @remote_socket_mock.stubs(:puts)

        @remote_interface.read_command('test_command')
      end

      def test_read_command_returns_input_with_trailing_whitespace_stripped
        @remote_socket_mock.stubs(:puts)
        @remote_socket_mock.stubs(:gets).returns("foo\r\n")
        result = @remote_interface.read_command('test_command')

        assert_equal(result, 'foo')
      end

      def test_read_command_with_no_input_raises_io_error
        @remote_socket_mock.stubs(:puts)
        @remote_socket_mock.stubs(:gets).returns(nil)

        assert_raises(IOError) do
          @remote_interface.read_command('test_command')
        end
      end
    end

    class CloseTest < RemoteInterfaceTest
      def test_close_calls_close_on_the_output_socket
        @remote_socket_mock.expects(:close)

        @remote_interface.close
      end

      def test_close_with_error_calls_print_on_error_socket
        @remote_socket_mock.stubs(:close).raises(IOError)
        @remote_socket_mock.expects(:print)
          .with("*** Error closing the interface...\n")

        @remote_interface.close
      end
    end

    class ConfirmTest < RemoteInterfaceTest
      def test_confirm_prompts_for_input_with_confirm
        @remote_socket_mock.expects(:puts).with('CONFIRM test_command')
        @remote_socket_mock.stubs(:gets).returns('y')

        @remote_interface.confirm('test_command')
      end

      def test_confirm_does_not_log_history
        @remote_socket_mock.stubs(:puts)
        @remote_socket_mock.stubs(:gets).returns('y')
        @remote_interface.history.expects(:push).never

        @remote_interface.confirm('test_command')
      end

      def test_confirm_returns_true_when_user_enters_y
        @remote_socket_mock.stubs(:puts)
        @remote_socket_mock.stubs(:gets).returns('y')
        result = @remote_interface.confirm('test_command')

        assert_equal(result, true)
      end

      def test_confirm_returns_false_when_user_does_not_enter_y
        @remote_socket_mock.stubs(:puts)
        @remote_socket_mock.stubs(:gets).returns('not y')
        result = @remote_interface.confirm('test_command')

        assert_equal(result, false)
      end
    end
  end
end
