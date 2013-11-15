module Byebug
  class Interface
    attr_writer :have_readline

    def initialize
      @have_readline = false
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

  require_relative 'interfaces/local_interface'
  require_relative 'interfaces/script_interface'
  require_relative 'interfaces/remote_interface'
end
