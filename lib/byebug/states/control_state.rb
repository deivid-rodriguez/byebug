require 'byebug/state'

module Byebug
  #
  # Controls state of Byebug's REPL when in control mode
  #
  class ControlState < State
    def proceed
    end

    extend Forwardable
    def_delegators :@interface, :errmsg, :puts

    def confirm(*_args)
      'y'
    end

    def context
      nil
    end

    def file
      errmsg 'No filename given.'
    end
  end
end
