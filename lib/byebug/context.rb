require 'byebug/frame'
require 'byebug/helpers/path'
require 'byebug/helpers/file'
require 'byebug/processors/command_processor'

module Byebug
  #
  # Mantains context information for the debugger and it's the main
  # communication point between the library and the C-extension through the
  # at_breakpoint, at_catchpoint, at_tracing, at_line and at_return callbacks
  #
  class Context
    include Helpers::FileHelper

    class << self
      include Helpers::PathHelper

      attr_writer :ignored_files

      #
      # List of files byebug will ignore while debugging
      #
      def ignored_files
        @ignored_files ||=
          Byebug.mode == :standalone ? lib_files + [bin_file] : lib_files
      end

      attr_writer :interface

      def interface
        @interface ||= LocalInterface.new
      end

      attr_writer :processor

      def processor
        @processor ||= CommandProcessor
      end
    end

    #
    # Tells whether a file is ignored by the debugger.
    #
    # @param path [String] filename to be checked.
    #
    def ignored_file?(path)
      self.class.ignored_files.include?(path)
    end

    def frame
      @frame ||= Frame.new(self, 0)
    end

    def frame=(pos)
      @frame = Frame.new(self, pos)
    end

    def file
      frame.file
    end

    def line
      frame.line
    end

    def location
      "#{normalize(file)}:#{line}"
    end

    def full_location
      return location if virtual_file?(file)

      "#{location} #{get_line(file, line)}"
    end

    #
    # Context's stack size
    #
    def stack_size
      return 0 unless backtrace

      backtrace.drop_while { |l| ignored_file?(l.first.path) }
        .take_while { |l| !ignored_file?(l.first.path) }
        .size
    end

    def interrupt
      step_into 1
    end

    def at_breakpoint(breakpoint)
      new_processor.at_breakpoint(breakpoint)
    end

    def at_catchpoint(exception)
      new_processor.at_catchpoint(exception)
    end

    def at_tracing(file, _line)
      return if ignored_file?(file)

      new_processor.at_tracing
    end

    def at_line(file, _l)
      self.frame = 0
      return if ignored_file?(file)

      new_processor.at_line
    end

    def at_return(file, _line)
      return if ignored_file?(file)

      new_processor.at_return
    end

    private

    def new_processor
      @processor ||= self.class.processor.new(self)
    end
  end
end
