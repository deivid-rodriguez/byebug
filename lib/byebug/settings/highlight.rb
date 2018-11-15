# frozen_string_literal: true

require "byebug/setting"

module Byebug
  #
  # Setting for adding color in the output.
  #
  class HighlightSetting < Setting
    DEFAULT = false

    def banner
      "Highlight code"
    end
  end
end
