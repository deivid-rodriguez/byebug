module Byebug
  class Autosave < Setting
    def initialize
      @value = true
    end

    def help
      'If true, command history record is saved on exit'
    end
  end

  Setting.settings[:autosave] = Autosave.new
end
