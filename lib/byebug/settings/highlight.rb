require 'byebug/setting'

module Byebug
  #
  # Setting to customize whether source-code listings use terminal colors.
  #
  class HighlightSetting < Setting
    DEFAULT = true

    def banner
      'Set whether we use terminal highlighting'
    end
  end
end
