module Byebug
  class Linetrace < Setting
    def help
      'Enable line execution tracing'
    end

    def value=(v)
      Byebug.tracing = v
    end

    def value
      Byebug.tracing?
    end
  end

  Setting.settings[:linetrace] = Linetrace.new
end
