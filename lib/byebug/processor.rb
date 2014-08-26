require 'forwardable'

module Byebug
  class Processor
    attr_accessor :interface

    extend Forwardable
    def_delegators :@interface, :errmsg, :puts

    def initialize(interface)
      @interface = interface
    end

    def without_exceptions
      yield
    rescue
      nil
    end
  end
end

require 'byebug/command'
require 'byebug/processors/command_processor'
require 'byebug/processors/control_command_processor'
