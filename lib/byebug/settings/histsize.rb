module Byebug
  class HistsizeSetting < Setting
    DEFAULT = 256

    def initialize
      @value = DEFAULT
    end

    def help
      "Customize maximum number of commands that can be stored in byebug's " \
      "history record. By default, #{DEFAULT}"
    end

    def to_s
      "Maximum size of byebug's command history is #{value}"
    end
  end
end
