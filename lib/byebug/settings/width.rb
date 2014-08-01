module Byebug
  class WidthSetting < Setting
    DEFAULT = 160

    def help
      "Number of characters per line in byebug's output"
    end

    def to_s
      "Maximum width of byebug's output is #{value}"
    end
  end
end
