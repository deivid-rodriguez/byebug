module Byebug
  #
  # Setting for automatic evaluation of unknown commands.
  #
  class AutoevalSetting < Setting
    DEFAULT = true

    def banner
      'Automatically evaluate unrecognized commands'
    end
  end
end
