# frozen_string_literal: true

require "byebug/setting"

module Byebug
  #
  # Setting to display full paths in backtraces.
  #
  class FullpathSetting < Setting
    DEFAULT = true

    def banner
      "Display full file names in backtraces"
    end
  end
end
