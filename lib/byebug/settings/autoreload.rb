module Byebug
  class Autoreload < Setting
    def initialize
      @value = true
    end

    def help
      'Reload source code when changed'
    end
  end

  Setting.settings[:autoreload] = Autoreload.new
end
