# frozen_string_literal: true

require "test_helper"
require "open3"

module Byebug
  #
  # Tests remote debugging functionality.
  #
  class RemoteTest < TestCase
    BYEBUG = File.absolute_path("../lib", __dir__)

    def self.define_test(name, &block)
      define_method("test_#{name}", &block)
    end

    def program_with_standard_remote_debugging
      strip_line_numbers <<-RUBY
         1:  require "byebug"
         2:
         3:  module Byebug
         4:    #
         5:    # Toy class to test remote debugging
         6:    #
         7:    class #{example_class}
         8:      def a
         9:        3
        10:      end
        11:    end
        12:
        13:    require "byebug/core"
        14:    self.wait_connection = true
        15:    self.start_server("127.0.0.1")
        16:
        17:    byebug
        18:
        19:    #{example_class}.new.a
        20:  end
      RUBY
    end

    def program_with_remote_debugging_shortcut
      strip_line_numbers <<-RUBY
         1:  require "byebug"
         2:
         3:  module Byebug
         4:    #
         5:    # Toy class to test remote debugging
         6:    #
         7:    class #{example_class}
         8:      def a
         9:        3
        10:      end
        11:    end
        12:
        13:    remote_byebug("127.0.0.1")
        14:
        15:    #{example_class}.new.a
        16:  end
      RUBY
    end

    def program_with_two_breakpoints
      strip_line_numbers <<-RUBY
         1:  require "byebug"
         2:  require "byebug/core"
         3:
         4:  module Byebug
         5:    #
         6:    # Toy class to test remote debugging
         7:    #
         8:    class #{example_class}
         9:      def a
        10:        3
        11:      end
        12:    end
        13:
        14:    self.wait_connection = true
        15:    self.start_server("127.0.0.1")
        16:
        17:    byebug
        18:    thingy = #{example_class}.new
        19:    byebug
        20:    thingy.a
        21:    sleep 3
        22:    thingy.a
        23:    byebug
        24:    thingy.a
        25:  end
      RUBY
    end

    %w[
      program_with_standard_remote_debugging
      program_with_remote_debugging_shortcut
    ].each do |code|
      define_test("connecting_to_remote_debugger_using_#{code}") do
        write_program(send(code))

        remote_debug_and_connect("quit!")

        check_output_includes \
          "Connecting to byebug server at 127.0.0.1:8989...",
          "Connected."
      end

      define_test("interacting_with_remote_debugger_using_#{code}") do
        write_program(send(code))

        remote_debug_and_connect("cont 9", "cont")

        check_output_includes \
          "7:   class ByebugExampleClass",
          "8:     def a",
          "=>  9:       3",
          "10:     end"
      end

      define_test("interrupting_client_doesnt_abort_server_using_#{code}") do
        write_program(send(code))

        status = remote_debug_connect_and_interrupt("cont")

        assert_equal true, status.success?
      end

      define_test("ignoring_main_server_and_control_threads_using_#{code}") do
        write_program(send(code))

        remote_debug_and_connect("thread list", "cont")

        check_output_includes \
          %r{!.*/byebug/remote/server.rb},
          %r{!.*/byebug/remote/server.rb}
      end
    end

    def test_interrupting_client_doesnt_abort_server_after_a_second_breakpoint
      write_program(program_with_two_breakpoints)

      status = remote_debug_connect_and_interrupt("cont")

      assert_equal true, status.success?
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
        sleep(windows? ? 3 : 1)
        Thread.kill(th)

        wait_th.value
      end
    end

    def remote_debug(*commands)
      enter(*commands)

      test_name = Thread.current.backtrace_locations[3].label

      Open3.popen2e(
        { "MINITEST_TEST" => test_name },
        "ruby -rsimplecov -I#{BYEBUG} #{example_path}"
      ) do |_i, _oe, t|
        yield(t)
      end
    end

    def launch_client
      Timeout.timeout(5) do
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
