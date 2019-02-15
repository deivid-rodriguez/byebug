# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

module Byebug
  #
  # Tests the local interface
  #
  class LocalInterfaceTest < TestCase
    def test_continues_by_control_d
      # `Reline.readline` returns nil for Control-D
      Reline.stub(:readline, nil) do
        interface = LocalInterface.new
        assert_equal "continue", interface.readline("(byebug)")
      end
    end
  end
end
