module Byebug
  #
  # Setting to allow consecutive repeated lines to be displayed when line
  # tracing is enabled.
  #
  class TracingPlusSetting < Setting
    def banner
      'Set line execution tracing to always show different lines'
    end
  end
end
