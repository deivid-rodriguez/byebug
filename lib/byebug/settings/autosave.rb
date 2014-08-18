module Byebug
  class AutosaveSetting < Setting
    DEFAULT = true

    def banner
      'Automatically save command history record on exit'
    end
  end
end
