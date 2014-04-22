module Byebug
  class ForcestepSetting < Setting
    def help
      'If true, next/step commands always move to a new line'
    end

    def print
      "forced-stepping is #{self.getter}"
    end
  end
end
