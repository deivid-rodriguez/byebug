# frozen_string_literal: true

require "byebug/command"
require "byebug/helpers/parse"

module Byebug
  #
  # Allows the user to continue execution until the next breakpoint, if
  # the breakpoint file or line be different, stop again
  #
  class ContinueBreakpointCommand < Command
    include Helpers::ParseHelper

    class << self
      attr_writer :file_line, :file_path

      def file_line
        @file_line ||= 0
      end

      def file_path
        @file_path ||= ""
      end
    end

    def self.regexp
      /^\s* c(?:ont(?:inue)?_)?(?:b(?:reak(?:point)?)?) \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        c[ont[inue]_]b[reak[point]]

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Runs until the next breakpoint as long as it is different from the current one"
    end

    def keep_execution(file, line)
      [self.class.file_path, self.class.file_line] == [file, line]
    end

    def reset_attributes
      self.class.always_run = 0
    end

    def auto_run
      return false unless self.class.always_run == 2

      keep_execution(frame.file, frame.line) ? processor.proceed! : reset_attributes
      true
    end

    def execute
      return if auto_run

      self.class.always_run = 2
      self.class.file_path = frame.file
      self.class.file_line = frame.line

      processor.proceed!
      Byebug.stop if Byebug.stoppable?
    end
  end
end
