module Byebug
  #
  # Setting to force changing lines when executing step or next commands.
  #
  class ForcestepSetting < Setting
    def banner
      'Force next/step commands to always move to a new line'
    end

    def print
      "forced-stepping is #{getter}"
    end
  end
end
