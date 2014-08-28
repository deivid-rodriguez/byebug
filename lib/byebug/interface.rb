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
    attr_accessor :command_queue, :restart_file

    def initialize
      @command_queue, @restart_file = [], nil
    end

    #
    # Common routine for reporting byebug error messages.
    # Derived classes may want to override this to capture output.
    #
    def errmsg(message)
      print("*** #{message}\n")
    end
  end

  require 'byebug/interfaces/local_interface'
  require 'byebug/interfaces/script_interface'
  require 'byebug/interfaces/remote_interface'
end
