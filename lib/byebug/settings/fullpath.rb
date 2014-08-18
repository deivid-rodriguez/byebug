module Byebug
  class FullpathSetting < Setting
    DEFAULT = true

    def banner
      'Display full file names in backtraces'
    end
  end
end
