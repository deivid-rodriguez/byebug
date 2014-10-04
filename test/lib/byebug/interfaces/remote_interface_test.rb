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

    def test_read_command
      # socket expected output, return value, args
      @remote_socket_mock.expect(:puts, nil, ["PROMPT test_command"])
      # socket expected input
      @remote_socket_mock.expect(:gets, "foo\r\n")
      # history object records the user input
      assert_send([@remote_interface.history, :push, "foo\r\n"])

      result = @remote_interface.read_command("test_command")
      # it should return input with trailing whitespace stripped
      assert_equal(result, "foo")

      @remote_socket_mock.verify()
    end

    def test_read_command_with_no_input
      # socket expected output
      @remote_socket_mock.expect(:puts, nil, ["PROMPT test_command"])
      # socket expected input
      @remote_socket_mock.expect(:gets, nil)

      assert_raises(IOError) do
        @remote_interface.read_command("test_command")
      end
      @remote_socket_mock.verify()
    end

    def test_close
      # (output) socket mock receives close
      @remote_socket_mock.expect(:close, nil)

      result = @remote_interface.close()
      @remote_socket_mock.verify()
    end

    def test_close_with_error
      def @remote_socket_mock.close
        raise IOError
      end

      @remote_socket_mock.expect(:print, nil,
                                 [ "*** Error closing the interface...\n"])

      result = @remote_interface.close()
      @remote_socket_mock.verify()
    end

    def test_confirm
      # it prompts for input with CONFIRM
      @remote_socket_mock.expect(:puts, nil, ["CONFIRM test_command"])
      # it reads user input
      @remote_socket_mock.expect(:gets, "y")

      # it doesn't log history
      fail_on_push = -> (pushed_message) do
        flunk("history should not be called, was called with #{pushed_message}")
      end
      @remote_interface.history.stub(:push, fail_on_push) do
        result = @remote_interface.confirm("test_command")
        # it returns true when the user input is "y"
        assert_equal(result, true)

        @remote_socket_mock.verify()
      end
    end

    def test_confirm_with_non_yes
      # it prompts for input with CONFIRM
      @remote_socket_mock.expect(:puts, nil, ["CONFIRM test_command"])
      # it reads user input
      @remote_socket_mock.expect(:gets, "anything else")

      result = @remote_interface.confirm("test_command")
      # it returns false when the user input is not "y"
      assert_equal(result, false)

      @remote_socket_mock.verify()
    end
  end
end
