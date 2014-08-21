module Byebug
  #
  # Setting for automatically reloading source code when it is changed.
  #
  class AutoreloadSetting < Setting
    DEFAULT = true

    def banner
      'Automatically reload source code when it is changed'
    end
  end
end
