module Byebug

  class Context

    class << self
      def stack_size
        if backtrace = Thread.current.backtrace_locations
          backtrace.drop_while { |l| ignored(l.path) || l.path == '(eval)' }
                   .take_while { |l| !ignored(l.path) }
                   .size
        end
      end

      def real_stack_size
        if backtrace = Thread.current.backtrace_locations
          backtrace.size
        end
      end

      def ignored(path)
        IGNORED_FILES.include?(path)
      end
      private :ignored
    end

    def frame_locals frame_no = 0
      bind = frame_binding frame_no
      eval "local_variables.inject({}){|h, v| h[v] = eval(v.to_s); h}", bind
    end

    def c_frame_args frame_no
      myself = frame_self frame_no
      return [] unless myself.to_s != 'main'
      myself.send(:method, frame_method(frame_no)).parameters
    end

    def ruby_frame_args bind
      return [] unless eval '__method__', bind
      begin
        eval "self.method(__method__).parameters", bind
      rescue NameError => e
        print "WARNING: Got exception #{e.class}: \"#{e.message}\" " \
              "while retreving parameters from frame\n"
        return []
      end
    end

    def frame_args frame_no = 0
      bind = frame_binding frame_no
      if bind.nil?
        c_frame_args frame_no
      else
        ruby_frame_args bind
      end
    end

    def handler
      Byebug.handler or raise 'No interface loaded'
    end

    def at_breakpoint(brkpnt)
      handler.at_breakpoint(self, brkpnt)
    end

    def at_catchpoint(excpt)
      handler.at_catchpoint(self, excpt)
    end

    def at_tracing(file, line)
      handler.at_tracing(self, file, line) unless IGNORED_FILES.include?(file)
    end

    def at_line(file, line)
      handler.at_line(self, file, line) unless IGNORED_FILES.include?(file)
    end

    def at_return(file, line)
      handler.at_return(self, file, line) unless IGNORED_FILES.include?(file)
    end
  end
end
