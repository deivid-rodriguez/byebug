module Byebug
  class AutolistSetting < Setting
    def initialize
      ListCommand.always_run = 1
    end

    def help
      'If true, `list` command is run everytime byebug stops'
    end

    def value=(v)
      ListCommand.always_run = v ? 1 : 0
    end

    def value
      ListCommand.always_run == 1
    end
  end
end
