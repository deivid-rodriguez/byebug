module Byebug
  class AutosaveSetting < Setting
    def initialize
      @value = true
    end

    def help
      'If true, command history record is saved on exit'
    end
  end
end
