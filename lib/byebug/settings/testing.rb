module Byebug
  class Testing < Setting
    def help
      'Used when testing byebug'
    end
  end

  Setting.settings[:testing] = Testing.new
end
