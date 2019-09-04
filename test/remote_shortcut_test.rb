# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/remote_debugging_tests"

module Byebug
  #
  # Tests the remote debugging shortcut.
  #
  class RemoteShortcutTest < TestCase
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
        13:    remote_byebug("127.0.0.1")
        14:
        15:    #{example_class}.new.a
        16:  end
      RUBY
    end
  end
end
