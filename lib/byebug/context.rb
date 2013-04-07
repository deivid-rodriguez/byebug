module Byebug

  class << self

    # interface modules provide +handler+ object
    attr_accessor :handler

  end

  class Context
    def frame_class(frame_no=0)
      frame_self(frame_no).class
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
