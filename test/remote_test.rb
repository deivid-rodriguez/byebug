# frozen_string_literal: true

require "test_helper"
require "open3"

module Byebug
  #
  # Tests remote debugging functionality.
  #
  class RemoteTest < TestCase
    def setup
      example_file.write(program)
      example_file.close
    end

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

    def test_connecting_to_the_remote_debugger
      remote_debug("quit!")

      check_output_includes \
        "Connecting to byebug server at 127.0.0.1:8989...",
        "Connected."
    end

    def test_interacting_with_the_remote_debugger
      remote_debug("cont 10", "cont")

      check_output_includes \
        "8:   class ByebugExampleClass",
        "9:     def a",
        "=> 10:       3",
        "11:     end"
    end

    private

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
