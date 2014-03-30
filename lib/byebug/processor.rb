require 'forwardable'
require_relative 'interface'
require_relative 'command'

module Byebug

  # Should this be a mixin?
  class Processor
    attr_accessor :interface

    extend Forwardable
    def_delegators :@interface, :errmsg, :print

    def initialize(interface)
      @interface = interface
    end
  end

  require_relative 'processors/command_processor'
  require_relative 'processors/control_command_processor'
end
