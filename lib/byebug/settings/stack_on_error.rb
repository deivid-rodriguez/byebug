# frozen_string_literal: true

require "byebug/setting"

module Byebug
  #
  # Setting to enable/disable the display of backtraces when evaluations raise
  # errors.
  #
  class StackOnErrorSetting < Setting
    def banner
      "Display stack trace when `eval` raises an exception"
    end
  end
end
