module Byebug
  class ListsizeSetting < Setting
    DEFAULT = 10

    def banner
      'Set number of source lines to list by default'
    end

    def to_s
      "Number of source lines to list is #{value}\n"
    end
  end
end
