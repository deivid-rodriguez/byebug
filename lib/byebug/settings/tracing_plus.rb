module Byebug
  class TracingPlus < Setting
    def help
      'Set line execution tracing to always show different lines'
    end
  end

  Setting.settings[:tracing_plus] = TracingPlus.new
end
