module Byebug

  class << self

    # interface modules provide +handler+ object
    attr_accessor :handler

  end

  class Context
    def frame_locals frame_no = 0
      bind = frame_binding frame_no
      eval "local_variables.inject({}){|h, v| h[v] = eval(v.to_s); h}", bind
    end

    def frame_args frame_no = 0
      bind = frame_binding frame_no
      return [] unless eval "__method__", bind
      eval "self.method(__method__).parameters", bind
    end

    def handler
      Byebug.handler or raise 'No interface loaded'
    end

    def at_breakpoint(breakpoint)
      handler.at_breakpoint(self, breakpoint) unless
        IGNORED_FILES.include?(breakpoint.source)
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
  end
end
