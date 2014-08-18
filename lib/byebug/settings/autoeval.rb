module Byebug
  class AutoevalSetting < Setting
    DEFAULT = true

    def banner
      'Automatically evaluate unrecognized commands'
    end
  end
end
