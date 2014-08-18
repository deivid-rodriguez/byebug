module Byebug
  class BasenameSetting < Setting
    def banner
      '<file>:<line> information after every stop uses short paths'
    end
  end
end
