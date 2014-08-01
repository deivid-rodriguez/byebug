module Byebug
  class AutolistSetting < Setting
    DEFAULT = 1

    def initialize
      ListCommand.always_run = DEFAULT
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
