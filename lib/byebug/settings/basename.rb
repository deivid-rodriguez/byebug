module Byebug
  class Basename < Setting
    def help
      'Filename display style.'
    end
  end

  Setting.settings[:basename] = Basename.new
end
