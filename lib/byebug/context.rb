module Byebug

  class << self

    # interface modules provide +handler+ object
    attr_accessor :handler

  end

  class Context
    def frame_args(frame_no=0)
      bind = frame_binding(frame_no)
      return [] unless eval "__method__", bind
      begin
        eval "self.method(__method__).parameters.map{|(attr, mid)| mid}", bind
      rescue NameError => e
        print "(WARNING: retreving args from frame #{frame_no} => " \
              "#{e.class} Exception: #{e.message})\n     "
        return []
      end
    end

    def interrupt
      self.stop_next = 1
    end

    def handler
      Byebug.handler or raise 'No interface loaded'
    end

    def at_breakpoint(breakpoint)
      handler.at_breakpoint(self, breakpoint)
    end

    def at_catchpoint(excpt)
      handler.at_catchpoint(self, excpt)
    end

    def at_tracing(file, line)
      handler.at_tracing(self, file, line)
    end

    def at_line(file, line)
      handler.at_line(self, file, line)
    end

    def at_return(file, line)
      handler.at_return(self, file, line)
    end

  end
end
