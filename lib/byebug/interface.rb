module Byebug
  class Interface
    attr_accessor :command_queue, :hist_size, :restart_file
    attr_writer :have_readline

    def initialize
      @command_queue, @have_readline, @hist_size = [], false, 256
    end

    # Common routine for reporting byebug error messages.
    # Derived classes may want to override this to capture output.
    def errmsg(*args)
      print '*** '
      print(*args)
    end

    def format(*args)
      if args.is_a?(Array)
        new_args = args.first
        new_args = new_args % args[1..-1] unless args[1..-1].empty?
      else
        new_args = args
      end
      new_args
    end

    def escape(msg)
      msg.gsub('%', '%%')
    end
  end

  require 'byebug/interfaces/local_interface'
  require 'byebug/interfaces/script_interface'
  require 'byebug/interfaces/remote_interface'
end
