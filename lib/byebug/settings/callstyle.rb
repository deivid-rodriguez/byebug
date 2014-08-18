module Byebug
  class CallstyleSetting < Setting
    DEFAULT = 'long'

    def banner
      'Set how you want method call parameters to be displayed'
    end

    def to_s
      "Frame display callstyle is '#{value}'"
    end
  end
end
