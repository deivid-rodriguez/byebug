module Byebug
  class Autoeval < Setting
    def initialize
      @value = true
    end

    def help
      'If true, byebug will evaluate every unrecognized command. If false, ' \
      'need to use the `eval` command to evaluate stuff'
    end
  end

  Setting.settings[:autoeval] = Autoeval.new
end
