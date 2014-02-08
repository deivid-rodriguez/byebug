require 'forwardable'
require_relative 'interface'

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

end
