# frozen_string_literal: true

require "test_helper"
require "open3"

module Byebug
  #
  # Tests remote debugging functionality.
  #
  class RemoteTest < TestCase
    def program
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
        18:
        19:    #{example_class}.new.a
        20:  end
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
        21:    sleep 5
        22:    thingy.a
        23:    byebug
        24:    thingy.a
        25:  end
      RUBY
    end

    def test_connecting_to_the_remote_debugger
      write_program(program)

      remote_debug("quit!")

      check_output_includes \
        "Connecting to byebug server at 127.0.0.1:8989...",
        "Connected."
    end

    def test_interacting_with_the_remote_debugger
      write_program(program)

      remote_debug("cont 10", "cont")

      check_output_includes \
        "8:   class ByebugExampleClass",
        "9:     def a",
        "=> 10:       3",
        "11:     end"
    end

    def test_interrupting_client_doesnt_abort_server
      skip unless Process.respond_to?(:fork)

      write_program(program)

      i, oe, t = Open3.popen2e(
        { "MINITEST_TEST" => __method__.to_s },
        "ruby -rsimplecov #{example_path}"
      )

      pid = fork do
        launch_client
      end

      sleep 1
      Process.kill("INT", pid)

      assert_equal true, t.value.success?

      i.close
      oe.close
    end

    def test_interrupting_client_doesnt_abort_server_after_a_second_breakpoint
      skip unless Process.respond_to?(:fork)

      write_program(program_with_two_breakpoints)

      i, oe, t = Open3.popen2e(
        { "MINITEST_TEST" => __method__.to_s },
        "ruby -rsimplecov #{example_path}"
      )

      enter "cont"

      pid = fork do
        launch_client
      end

      sleep 1
      Process.kill("INT", pid)

      assert_equal true, t.value.success?

      i.close
      oe.close
    end

    private

    def write_program(code)
      example_file.write(code)
      example_file.close
    end

    def remote_debug(*commands)
      enter(*commands)

      Open3.popen2e("ruby #{example_path}") do |_i, _oe, t|
        launch_client

        t.value
      end
    end

    def launch_client
      Timeout.timeout(1) do
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
