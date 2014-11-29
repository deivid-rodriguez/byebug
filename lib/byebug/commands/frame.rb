# encoding: utf-8

require 'pathname'

module Byebug
  #
  # Mixin to assist command parsing
  #
  module FrameFunctions
    def c_frame?(frame_no)
      @state.context.frame_binding(frame_no).nil?
    end

    def switch_to_frame(frame_no)
      frame_no >= 0 ? frame_no : @state.context.stack_size + frame_no
    end

    def navigate_to_frame(jump_no)
      return if jump_no == 0
      total_jumps, current_jumps, new_pos = jump_no.abs, 0, @state.frame_pos
      step = jump_no / total_jumps # +1 (up) or -1 (down)

      loop do
        new_pos += step
        break if new_pos < 0 || new_pos >= @state.context.stack_size

        next if c_frame?(new_pos)

        current_jumps += 1
        break if current_jumps == total_jumps
      end
      new_pos
    end

    def adjust_frame(frame_pos, absolute)
      if absolute
        abs_frame_pos = switch_to_frame(frame_pos)
        return errmsg(pr('frame.errors.c_frame')) if c_frame?(abs_frame_pos)
      else
        abs_frame_pos = navigate_to_frame(frame_pos)
      end

      if abs_frame_pos >= @state.context.stack_size
        return errmsg(pr('frame.errors.too_low'))
      elsif abs_frame_pos < 0
        return errmsg(pr('frame.errors.too_high'))
      end

      @state.frame_pos = abs_frame_pos
      @state.file = @state.context.frame_file @state.frame_pos
      @state.line = @state.context.frame_line @state.frame_pos
      @state.prev_line = nil
      ListCommand.new(@state).execute
    end

    def get_frame_class(style, pos)
      frame_class = style == 'short' ? '' : "#{@state.context.frame_class pos}"
      frame_class == '' ? '' : "#{frame_class}."
    end

    def get_frame_block_and_method(pos)
      frame_deco_regexp = /((?:block(?: \(\d+ levels\))?|rescue) in )?(.+)/
      frame_deco_method = "#{@state.context.frame_method(pos)}"
      frame_block_and_method = frame_deco_regexp.match(frame_deco_method)[1..2]
      frame_block_and_method.map { |x| x.nil? ? '' : x }
    end

    def get_frame_args(style, pos)
      args = @state.context.frame_args(pos)
      return '' if args.empty?

      locals = @state.context.frame_locals pos if style == 'long'
      my_args = args.map do |arg|
        case arg[0]
        when :block
          prefix, default = '&', 'block'
        when :rest
          prefix, default = '*', 'args'
        else
          prefix, default = '', nil
        end

        klass = style == 'long' && arg[1] ? "##{locals[arg[1]].class}" : ''
        "#{prefix}#{arg[1] || default}#{klass}"
      end

      "(#{my_args.join(', ')})"
    end

    def get_frame_call(pos)
      frame_block, frame_method = get_frame_block_and_method(pos)
      frame_class = get_frame_class(Setting[:callstyle], pos)
      frame_args = get_frame_args(Setting[:callstyle], pos)

      frame_block + frame_class + frame_method + frame_args
    end

    def shortpath(fullpath)
      components = Pathname(fullpath).each_filename.to_a
      return File.join(components) if components.size <= 2

      File.join('...', components[-3..-1])
    end

    def get_pr_arguments(pos)
      fullpath = @state.context.frame_file(pos)
      file = CommandProcessor.canonic_file(
        Setting[:fullpath] ? fullpath : shortpath(fullpath)
      )
      line = @state.context.frame_line(pos)

      mark = (pos == @state.frame_pos) ? '--> ' : '    '
      mark += c_frame?(pos) ? ' ͱ-- ' : ''
      call_str = get_frame_call(pos)

      { mark: mark,
        pos: format('%-2d', pos),
        call_str: "#{call_str} ",
        file: file,
        line: line }
    end

    def print_backtrace
      bt = prc('frame.line', (0...@state.context.stack_size)) do |_, index|
        get_pr_arguments(index)
      end

      print(bt)
    end
  end

  #
  # Show current backtrace.
  #
  class WhereCommand < Command
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
        %(w[here]|bt|backtrace        Display stack frames.

          Print the entire stack frame. Each frame is numbered; the most recent
          frame is 0. A frame number can be referred to in the "frame" command;
          "up" and "down" add or subtract respectively to frame numbers shown.
          The position of the current frame is marked with -->. C-frames hang
          from their most immediate Ruby frame to indicate that they are not
          navigable.)
      end
    end
  end

  #
  # Move the current frame up in the backtrace.
  #
  class UpCommand < Command
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
        %(up[ count]        Move to higher frame.)
      end
    end
  end

  #
  # Move the current frame down in the backtrace.
  #
  class DownCommand < Command
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
        %(down[ count]        Move to lower frame.)
      end
    end
  end

  #
  # Move to specific frames in the backtrace.
  #
  class FrameCommand < Command
    def regexp
      /^\s* f(?:rame)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      unless @match[1]
        print(pr('frame.line', get_pr_arguments(@state.frame_pos)))
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
        %(f[rame][ frame-number]

          Move the current frame to the specified frame number, or the 0 if no
          frame-number has been given.

          A negative number indicates position from the other end, so
          "frame -1" moves to the oldest frame, and "frame 0" moves to the
          newest frame.

          Without an argument, the command prints the current stack frame. Since
          the current position is redisplayed, it may trigger a resyncronization
          if there is a front end also watching over things.)
      end
    end
  end
end
