module Byebug
  class AutoirbSetting < Setting
    DEFAULT = 0

    def initialize
      IrbCommand.always_run = DEFAULT
    end

    def help
      'Invoke IRB on every stop'
    end

    def value=(v)
      IrbCommand.always_run = v ? 1 : 0
    end

    def value
      IrbCommand.always_run == 1
    end
  end
end
