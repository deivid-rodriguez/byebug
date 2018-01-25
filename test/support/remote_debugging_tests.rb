# frozen_string_literal: true

require "test_helper"
require "open3"

module Byebug
  #
  # Tests remote debugging functionality.
  #
  module RemoteDebuggingTests
    def test_connecting_to_remote_debugger
      write_program(program)

      remote_debug_and_connect("quit!")

      check_output_includes \
        "Connecting to byebug server at 127.0.0.1:8989...",
        "Connected."
    end

    def test_interacting_with_remote_debugger
      write_program(program)

      remote_debug_and_connect("cont 9", "cont")

      check_output_includes \
        "7:   class ByebugExampleClass",
        "8:     def a",
        "=>  9:       3",
        "10:     end"
    end

    def test_interrupting_client_doesnt_abort_server
      write_program(program)

      status = remote_debug_connect_and_interrupt("cont")

      assert_equal true, status.success?
    end

    def test_ignoring_main_server_and_control_threads
      write_program(program)

      remote_debug_and_connect("thread list", "cont")

      check_output_includes \
        %r{!.*/byebug/remote/server.rb},
        %r{!.*/byebug/remote/server.rb}
    end

    private

    def write_program(code)
      example_file.write(code)
      example_file.close
    end

    def remote_debug_and_connect(*commands)
      remote_debug(*commands) do |wait_th|
        launch_client

        wait_th.value
      end
    end

    def remote_debug_connect_and_interrupt(*commands)
      remote_debug(*commands) do |wait_th|
        th = Thread.new { launch_client }
        sleep(7)
        Thread.kill(th)

        wait_th.value
      end
    end

    def remote_debug(*commands)
      enter(*commands)

      Open3.popen2e(shell_out_env, "ruby #{example_path}") do |_i, _oe, t|
        yield(t)
      end
    end

    def launch_client
      Timeout.timeout(7) do
        begin
          Byebug.start_client("127.0.0.1")
        rescue Errno::ECONNREFUSED
          sleep 0.1
          retry
        end
      end
    end
  end
end
