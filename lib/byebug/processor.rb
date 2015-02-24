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

    def self.load_commands
      Dir.glob(File.expand_path('../commands/*.rb', __FILE__)).each do |file|
        require file
      end
    end
  end

  Processor.load_commands
end

require 'byebug/processors/command_processor'
require 'byebug/processors/control_command_processor'
