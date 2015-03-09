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

    def self.load_settings
      Dir.glob(File.expand_path('../settings/*.rb', __FILE__)).each do |file|
        require file
      end

      Byebug.constants.grep(/[a-z]Setting/).map do |name|
        setting = Byebug.const_get(name).new
        Byebug::Setting.settings[setting.to_sym] = setting
      end
    end
  end

  Processor.load_commands
  Processor.load_settings
end

require 'byebug/processors/command_processor'
require 'byebug/processors/control_command_processor'
