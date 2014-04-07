require 'forwardable'

module Byebug
  class Processor
    attr_accessor :interface

    extend Forwardable
    def_delegators :@interface, :errmsg, :print

    def initialize(interface)
      @interface = interface
    end
  end
end

require 'byebug/command'
require 'byebug/processors/command_processor'
require 'byebug/processors/control_command_processor'
