# encoding: utf-8

require 'pathname'
require 'byebug/command'
require 'byebug/helpers/frame'
require 'byebug/helpers/parse'

module Byebug
  #
  # Move to specific frames in the backtrace.
  #
  class FrameCommand < Command
    include Helpers::FrameHelper
    include Helpers::ParseHelper

    def regexp
      /^\s* f(?:rame)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      unless @match[1]
        print(pr('frame.line', get_pr_arguments(@state.frame)))
        return
      end

      pos, err = get_int(@match[1], 'Frame')
      return errmsg(err) unless pos

      adjust_frame(pos, true)
    end

    def description
      <<-EOD
        f[rame][ frame-number]

        Move the current frame to the specified frame number, or the 0 if no
        frame-number has been given.

        A negative number indicates position from the other end, so "frame -1"
        moves to the oldest frame, and "frame 0" moves to the newest frame.

        Without an argument, the command prints the current stack frame. Since
        the current position is redisplayed, it may trigger a resyncronization
        if there is a front end also watching over things.

        Use the "bt" command to find out where you want to go.
      EOD
    end
  end
end
