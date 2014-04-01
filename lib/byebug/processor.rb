require 'forwardable'
require 'byebug/interface'

# Should this be a mixin?
class Byebug::Processor
  attr_accessor :interface

  extend Forwardable
  def_delegators :@interface, :errmsg, :print

  def initialize(interface)
    @interface = interface
  end
end

require 'byebug/command'
require 'byebug/processors/command_processor'
require 'byebug/processors/control_command_processor'
