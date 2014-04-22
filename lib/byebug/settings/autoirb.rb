module Byebug
  class Autoirb < Setting
    def initialize
      IrbCommand.always_run = 0
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

  Setting.settings[:autoirb] = Autoirb.new
end
