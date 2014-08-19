module Byebug
  class Interface
    attr_accessor :command_queue, :restart_file

    def initialize
      @command_queue, @restart_file = [], nil
    end

    # Common routine for reporting byebug error messages.
    # Derived classes may want to override this to capture output.
    def errmsg(*args)
      print '*** '
      print(*args)
    end

    def escape(msg)
      msg.gsub('%', '%%')
    end
  end

  require 'byebug/interfaces/local_interface'
  require 'byebug/interfaces/script_interface'
  require 'byebug/interfaces/remote_interface'
end
