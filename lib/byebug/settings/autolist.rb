module Byebug
  class Autolist < Setting
    def initialize
      Byebug::ListCommand.always_run = 1
    end

    def help
      'If true, `list` command is run everytime byebug stops'
    end

    def value=(v)
      ListCommand.always_run = v
    end

    def value
      ListCommand.always_run
    end
  end

  Setting.settings[:autolist] = Autolist.new
end
