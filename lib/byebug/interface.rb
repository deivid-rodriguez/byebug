require 'byebug/history'

#
# Namespace for all of byebug's code
#
module Byebug
  #
  # Main Interface class
  #
  # Contains common functionality to all implemented interfaces.
  #
  class Interface
    attr_accessor :command_queue, :history

    def initialize
      @command_queue, @history = [], History.new
    end

    #
    # Common routine for reporting byebug error messages.
    # Derived classes may want to override this to capture output.
    #
    def errmsg(message)
      print("*** #{message}\n")
    end

    protected

    #
    # Stores <cmd> in commands history.
    #
    def save_history(cmd)
      @history.push(cmd) unless @history.ignore?(cmd)
    end
  end

  require 'byebug/interfaces/local_interface'
  require 'byebug/interfaces/script_interface'
  require 'byebug/interfaces/remote_interface'
end
