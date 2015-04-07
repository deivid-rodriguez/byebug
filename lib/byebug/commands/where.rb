# encoding: utf-8

require 'pathname'
require 'byebug/command'
require 'byebug/helpers/frame'

module Byebug
  #
  # Show current backtrace.
  #
  class WhereCommand < Command
    include Helpers::FrameHelper

    def regexp
      /^\s* (?:w(?:here)?|bt|backtrace) \s*$/x
    end

    def execute
      print_backtrace
    end

    def description
      <<-EOD
        w[here]|bt|backtrace

        Display stack frames.

        Print the entire stack frame. Each frame is numbered; the most recent
        frame is 0. A frame number can be referred to in the "frame" command.
        "up" and "down" add or subtract respectively to frame numbers shown.
        The position of the current frame is marked with -->. C-frames hang
        from their most immediate Ruby frame to indicate that they are not
        navigable.
      EOD
    end

    private

    def print_backtrace
      bt = prc('frame.line', (0...@state.context.stack_size)) do |_, index|
        get_pr_arguments(index)
      end

      print(bt)
    end
  end
end
