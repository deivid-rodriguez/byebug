module Byebug
  class Listsize < Setting
    def initialize
      @value = 10
    end

    def help
      'Set number of source lines to list by default'
    end

    def to_s
      "Number of source lines to list is #{value}"
    end
  end

  Setting.settings[:listsize] = Listsize.new
end
