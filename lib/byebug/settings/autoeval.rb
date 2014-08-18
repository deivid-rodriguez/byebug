module Byebug
  class AutoevalSetting < Setting
    DEFAULT = true

    def initialize
      EvalCommand.unknown = DEFAULT
    end

    def banner
      'Automatically evaluate unrecognized commands'
    end

    def value=(v)
      EvalCommand.unknown = v
    end

    def value
      EvalCommand.unknown
    end
  end
end
