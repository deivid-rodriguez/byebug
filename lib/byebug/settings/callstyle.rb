module Byebug
  class Callstyle < Setting
    def initialize
      @value = :long
    end

    def help
      'Set how you want method call parameters to be displayed'
    end

    def to_s
      "Frame display callstyle is :#{value}"
    end
  end

  Setting.settings[:callstyle] = Callstyle.new
end
