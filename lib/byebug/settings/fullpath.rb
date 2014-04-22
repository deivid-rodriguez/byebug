module Byebug
  class FullpathSetting < Setting
    def initialize
      @value = true
    end

    def help
      'Display full file names in frames'
    end
  end
end
