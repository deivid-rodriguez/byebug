module Byebug
  class LinetraceSetting < Setting
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
end
