# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/remote_debugging_tests"

module Byebug
  #
  # Tests remote debugging functionality.
  #
  class RemoteDebuggingTest < TestCase
    include RemoteDebuggingTests

    def program
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
        19:    thingy.a
        20:    sleep 3
        21:    thingy.a
        22:    byebug
        23:    thingy.a
        24:  end
      RUBY
    end

    def test_interrupting_client_doesnt_abort_server_after_a_second_breakpoint
      write_program(program_with_two_breakpoints)

      status = remote_debug_connect_and_interrupt("cont")

      assert_equal true, status.success?
    end
  end
end
