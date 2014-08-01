module Byebug
  class AutosaveSetting < Setting
    DEFAULT = true

    def help
      'If true, command history record is saved on exit'
    end
  end
end
