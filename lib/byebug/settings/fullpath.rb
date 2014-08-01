module Byebug
  class FullpathSetting < Setting
    DEFAULT = true

    def help
      'Display full file names in frames'
    end
  end
end
