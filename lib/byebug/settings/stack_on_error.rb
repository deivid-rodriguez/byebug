module Byebug
  class StackOnErrorSetting < Setting
    def banner
      'Display stack trace when `eval` raises an exception'
    end
  end
end
