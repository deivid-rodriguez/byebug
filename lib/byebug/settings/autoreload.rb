module Byebug
  class AutoreloadSetting < Setting
    DEFAULT = true

    def banner
      'Automatically reload source code when it is changed'
    end
  end
end
