module Byebug
  class AutoreloadSetting < Setting
    def initialize
      @value = true
    end

    def help
      'Reload source code when changed'
    end
  end
end
