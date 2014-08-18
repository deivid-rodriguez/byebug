module Byebug
  class ForcestepSetting < Setting
    def banner
      'Force next/step commands to always move to a new line'
    end

    def print
      "forced-stepping is #{getter}"
    end
  end
end
