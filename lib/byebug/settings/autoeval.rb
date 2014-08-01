module Byebug
  class AutoevalSetting < Setting
    DEFAULT = true

    def initialize
      EvalCommand.unknown = DEFAULT
    end

    def help
      'If true, byebug will evaluate every unrecognized command. If false, ' \
      'need to use the `eval` command to evaluate stuff'
    end

    def value=(v)
      EvalCommand.unknown = v
    end

    def value
      EvalCommand.unknown
    end
  end
end
