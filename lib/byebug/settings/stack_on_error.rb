module Byebug
  class StackOnErrorSetting < Setting
    def help
      'Display stack trace when "eval" raises an exception'
    end
  end
end
