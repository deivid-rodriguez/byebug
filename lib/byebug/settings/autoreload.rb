module Byebug
  class AutoreloadSetting < Setting
    DEFAULT = true

    def help
      'Reload source code when changed'
    end
  end
end
