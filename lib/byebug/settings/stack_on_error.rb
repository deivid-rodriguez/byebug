module Byebug
  class StackOnError < Setting
    def help
      'Display stack trace when "eval" raises an exception'
    end
  end

  Setting.settings[:stack_on_error] = StackOnError.new
end
