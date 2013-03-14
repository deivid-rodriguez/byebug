module Byebug

  class << self

    # interface modules provide +handler+ object
    attr_accessor :handler

  end

  class Context

    def frame_locals(frame_no=0)
      result = {}
      binding = frame_binding(frame_no)
      locals = eval("local_variables", binding)
      locals.each {|local| result[local.to_s] = eval(local.to_s, binding)}
      result
    end

    def frame_class(frame_no=0)
      frame_self(frame_no).class
    end

    def frame_args_info(frame_no=0)
      nil
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
      @tracing_started = File.identical?(file, Byebug::PROG_SCRIPT)
      handler.at_tracing(self, file, line) if @tracing_started
    end

    def at_line(file, line)
      handler.at_line(self, file, line)
    end

    def at_return(file, line)
      handler.at_return(self, file, line)
    end

  end
end
