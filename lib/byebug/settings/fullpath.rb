module Byebug
  class Fullpath < Setting
    def initialize
      @value = true
    end

    def help
      'Display full file names in frames'
    end
  end

  Setting.settings[:fullpath] = Fullpath.new
end
