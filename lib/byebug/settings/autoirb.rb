module Byebug
  class Autoirb < Setting
    def help
      'Invoke IRB on every stop'
    end
  end

  Setting.settings[:autoirb] = Autoirb.new
end
