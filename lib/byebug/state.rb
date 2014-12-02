module Byebug
  #
  # Common parent class for all of Byebug's states
  #
  class State
    attr_reader :commands, :interface

    def initialize(interface, commands)
      @interface = interface
      @commands = commands
    end
  end
end
