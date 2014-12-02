require 'byebug/state'

module Byebug
  #
  # Controls state of Byebug's REPL when in normal mode
  #
  class RegularState < State
    attr_accessor :context, :display, :file, :frame_pos, :line, :prev_line
    attr_writer :commands, :interface

    def initialize(commands, context, display, file, interface, line)
      super(interface, commands)
      @context = context
      @display = display
      @file = file
      @frame_pos = 0
      @line = line
      @prev_line = nil
      @proceed = false
    end

    extend Forwardable
    def_delegators :@interface, :errmsg, :puts, :print, :confirm

    def proceed?
      @proceed
    end

    def proceed
      @proceed = true
    end

    def location
      l = "#{self.class.canonic_file(@file)} @ #{@line}\n"
      l += "#{get_line(@file, @line)}\n" unless %w((irb) -e').include?(@file)
      l
    end
  end
end
