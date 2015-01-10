module Byebug
  #
  # Common parent class for all of Byebug's states
  #
  class State
    attr_reader :interface

    def initialize(interface)
      @interface = interface
    end
  end
end
