require 'byebug/command'

# encoding: utf-8

require 'pathname'

module Byebug
  #
  # Mixin to assist command parsing
  #
  module FrameFunctions
    def switch_to_frame(frame_no)
      frame_no >= 0 ? frame_no : @state.context.stack_size + frame_no
    end

    def navigate_to_frame(jump_no)
      return if jump_no == 0
      total_jumps, current_jumps, new_pos = jump_no.abs, 0, @state.frame
      step = jump_no / total_jumps # +1 (up) or -1 (down)

      loop do
        new_pos += step
        break if new_pos < 0 || new_pos >= @state.context.stack_size

        next if @state.c_frame?(new_pos)

        current_jumps += 1
        break if current_jumps == total_jumps
      end
      new_pos
    end

    def adjust_frame(frame, absolute)
      if absolute
        abs_frame = switch_to_frame(frame)
        return errmsg(pr('frame.errors.c_frame')) if @state.c_frame?(abs_frame)
      else
        abs_frame = navigate_to_frame(frame)
      end

      if abs_frame >= @state.context.stack_size
        return errmsg(pr('frame.errors.too_low'))
      elsif abs_frame < 0
        return errmsg(pr('frame.errors.too_high'))
      end

      @state.frame = abs_frame
      @state.file = @state.context.frame_file(@state.frame)
      @state.line = @state.context.frame_line(@state.frame)
      @state.prev_line = nil

      ListCommand.new(@state).execute if Setting[:autolist]
    end

    def get_pr_arguments(frame_no)
      file = @state.frame_file(frame_no)
      line = @state.frame_line(frame_no)
      call = @state.frame_call(frame_no)
      mark = @state.frame_mark(frame_no)
      pos = @state.frame_pos(frame_no)

      { mark: mark, pos: pos, call: call, file: file, line: line }
    end
  end

  #
  # Show current backtrace.
  #
  class WhereCommand < Command
    include FrameFunctions

    def regexp
      /^\s* (?:w(?:here)?|bt|backtrace) \s*$/x
    end

    def execute
      print_backtrace
    end

    class << self
      def names
        %w(where backtrace bt)
      end

      def description
        prettify <<-EOD
          w[here]|bt|backtrace        Display stack frames.

          Print the entire stack frame. Each frame is numbered; the most recent
          frame is 0. A frame number can be referred to in the "frame" command;
          "up" and "down" add or subtract respectively to frame numbers shown.
          The position of the current frame is marked with -->. C-frames hang
          from their most immediate Ruby frame to indicate that they are not
          navigable.
        EOD
      end
    end

    private

    def print_backtrace
      bt = prc('frame.line', (0...@state.context.stack_size)) do |_, index|
        get_pr_arguments(index)
      end

      print(bt)
    end
  end

  #
  # Move the current frame up in the backtrace.
  #
  class UpCommand < Command
    include FrameFunctions

    def regexp
      /^\s* u(?:p)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      pos, err = parse_steps(@match[1], 'Up')
      return errmsg(err) unless pos

      adjust_frame(pos, false)
    end

    class << self
      def names
        %w(up)
      end

      def description
        prettify <<-EOD
          up[ count] Move to higher frame.
        EOD
      end
    end
  end

  #
  # Move the current frame down in the backtrace.
  #
  class DownCommand < Command
    include FrameFunctions

    def regexp
      /^\s* down (?:\s+(\S+))? \s*$/x
    end

    def execute
      pos, err = parse_steps(@match[1], 'Down')
      return errmsg(err) unless pos

      adjust_frame(-pos, false)
    end

    class << self
      def names
        %w(down)
      end

      def description
        prettify <<-EOD
          down[ count] Move to lower frame.
        EOD
      end
    end
  end

  #
  # Move to specific frames in the backtrace.
  #
  class FrameCommand < Command
    include FrameFunctions

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

    class << self
      def names
        %w(frame)
      end

      def description
        prettify <<-EOD
          f[rame][ frame-number]

          Move the current frame to the specified frame number, or the 0 if no
          frame-number has been given.

          A negative number indicates position from the other end, so
          "frame -1" moves to the oldest frame, and "frame 0" moves to the
          newest frame.

          Without an argument, the command prints the current stack frame. Since
          the current position is redisplayed, it may trigger a resyncronization
          if there is a front end also watching over things.
        EOD
      end
    end
  end
end
