module Byebug
  #
  # Mantains context information for the debugger and it's the main
  # communication point between the library and the C-extension through the
  # at_breakpoint, at_catchpoint, at_tracing, at_line and at_return callbacks
  #
  class Context
    #
    # List of files byebug will ignore while debugging
    #
    def self.ignored_files
      Byebug.mode == :standalone ? lib_files + [bin_file] : lib_files
    end

    def self.bin_file
      @bin_file ||= Gem.bin_path('byebug', 'byebug')
    end

    def self.lib_files
      @lib_files ||= Dir.glob(File.expand_path('../../**/*.rb', __FILE__))
    end

    #
    # Tells whether a file is ignored by the debugger.
    #
    # @param path [String] filename to be checked.
    #
    def ignored_file?(path)
      self.class.ignored_files.include?(path)
    end

    def stack_size
      return 0 unless backtrace

      backtrace.drop_while { |l| ignored_file?(l.first.path) }
        .take_while { |l| !ignored_file?(l.first.path) }
        .size
    end

    def interrupt
      step_into 1
    end

    #
    # Gets local variables for a frame.
    #
    # @param frame_no Frame index in the backtrace. Defaults to 0.
    #
    # TODO: Use brand new local_variable_{get,set,defined?} for rubies >= 2.1
    #
    def frame_locals(frame_no = 0)
      bind = frame_binding(frame_no)
      return [] unless bind

      bind.eval('local_variables.inject({}){|h, v| h[v] = eval(v.to_s); h}')
    end

    #
    # Gets current method arguments for a frame.
    #
    # @param frame_no Frame index in the backtrace. Defaults to 0.
    #
    def frame_args(frame_no = 0)
      bind = frame_binding(frame_no)
      return c_frame_args(frame_no) unless bind

      ruby_frame_args(bind)
    end

    def handler
      Byebug.handler || fail('No interface loaded')
    end

    def at_breakpoint(brkpnt)
      handler.at_breakpoint(self, brkpnt)
    end

    def at_catchpoint(excpt)
      handler.at_catchpoint(self, excpt)
    end

    def at_tracing(file, line)
      handler.at_tracing(self, file, line) unless ignored_file?(file)
    end

    def at_line(file, line)
      handler.at_line(self, file, line) unless ignored_file?(file)
    end

    def at_return(file, line)
      handler.at_return(self, file, line) unless ignored_file?(file)
    end

    private

    #
    # Gets method arguments for a c-frame.
    #
    # @param frame_no Frame index in the backtrace.
    #
    def c_frame_args(frame_no)
      myself = frame_self(frame_no)
      return [] unless myself.to_s != 'main'

      myself.method(frame_method(frame_no)).parameters
    end

    #
    # Gets method arguments for a ruby-frame.
    #
    # @param bind Binding for the ruby-frame.
    #
    def ruby_frame_args(bind)
      return [] unless bind.eval('__method__')

      bind.eval('method(__method__).parameters')
    rescue NameError => e
      Byebug.errmsg \
        "Exception #{e.class} (#{e.message}) while retreving frame params"
      []
    end
  end
end
