module Byebug
  class Verbose < Setting
    def help
     'Enable verbose output of TracePoint API events'
    end
  end

  Setting.settings[:verbose] = Verbose.new
end
