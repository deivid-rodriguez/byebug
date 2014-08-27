# encoding: utf-8
module Byebug
  #
  # Mixin to assist command parsing
  #
  module FrameFunctions
    def c_frame?(frame_no)
      @state.context.frame_binding(frame_no).nil?
    end

    def switch_to_frame(frame_no)
      frame_no >= 0 ? frame_no : Context.stack_size + frame_no
    end

    def navigate_to_frame(jump_no)
      return if jump_no == 0
      total_jumps, current_jumps, new_pos = jump_no.abs, 0, @state.frame_pos
      step = jump_no / total_jumps
      loop do
        new_pos += step
        return new_pos if new_pos < 0 || new_pos >= Context.stack_size

        next if c_frame?(new_pos)

        current_jumps += 1
        break if current_jumps == total_jumps
      end
      new_pos
    end

    def adjust_frame(frame_pos, absolute)
      if absolute
        abs_frame_pos = switch_to_frame(frame_pos)
        return errmsg("Can't navigate to c-frame") if c_frame?(abs_frame_pos)
      else
        abs_frame_pos = navigate_to_frame(frame_pos)
      end

      if abs_frame_pos >= Context.stack_size
        return errmsg("Can't navigate beyond the oldest frame")
      elsif abs_frame_pos < 0
        return errmsg("Can't navigate beyond the newest frame")
      end

      @state.frame_pos = abs_frame_pos
      @state.file = @state.context.frame_file @state.frame_pos
      @state.line = @state.context.frame_line @state.frame_pos
      @state.previous_line = nil
      ListCommand.new(@state).execute
    end

    def get_frame_class(style, pos)
      frame_class = style == 'short' ? '' : "#{@state.context.frame_class pos}"
      frame_class == '' ? '' : "#{frame_class}."
    end

    def get_frame_block_and_method(pos)
      frame_deco_regexp = /((?:block(?: \(\d+ levels\))?|rescue) in )?(.+)/
      frame_deco_method = "#{@state.context.frame_method pos}"
      frame_block_and_method = frame_deco_regexp.match(frame_deco_method)[1..2]
      frame_block_and_method.map { |x| x.nil? ? '' : x }
    end

    def get_frame_args(style, pos)
      args = @state.context.frame_args pos
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

    def get_frame_call(prefix, pos)
      frame_block, frame_method = get_frame_block_and_method(pos)
      frame_class = get_frame_class(Setting[:callstyle], pos)
      frame_args = get_frame_args(Setting[:callstyle], pos)

      call_str = frame_block + frame_class + frame_method + frame_args

      max_call_str_size = Setting[:width] - prefix.size
      if call_str.size > max_call_str_size
        call_str = call_str[0..max_call_str_size - 5] + '...)'
      end

      call_str
    end

    def print_backtrace
      realsize = Context.stack_size
      calcedsize = @state.context.calced_stack_size
      if calcedsize != realsize
        if Byebug.post_mortem?
          stacksize = calcedsize
        else
          errmsg "Byebug's stacksize (#{calcedsize}) should be #{realsize}. " \
                 "This might be a bug in byebug or ruby's debugging API's\n"
          stacksize = realsize
        end
      else
        stacksize = calcedsize
      end
      (0...stacksize).each do |idx|
        print_frame(idx)
      end
    end

    require 'pathname'

    def shortpath(fullpath)
      components = Pathname(fullpath).each_filename.to_a
      return File.join(components) if components.size <= 2

      File.join('...', components[-3..-1])
    end

    def print_frame(pos, mark_current = true)
      fullpath = @state.context.frame_file(pos)
      file = Setting[:fullpath] ? fullpath : shortpath(fullpath)
      line = @state.context.frame_line(pos)

      if mark_current
        frame_str = (pos == @state.frame_pos) ? '--> ' : '    '
      else
        frame_str = ''
      end
      frame_str += c_frame?(pos) ? ' ͱ-- ' : ''

      frame_str += format('#%-2d ', pos)
      frame_str += get_frame_call frame_str, pos
      file_line = "at #{CommandProcessor.canonic_file(file)}:#{line}"
      if frame_str.size + file_line.size + 1 > Setting[:width]
        frame_str += "\n      #{file_line}"
      else
        frame_str += " #{file_line}"
      end

      puts frame_str
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
      return print_frame @state.frame_pos unless @match[1]

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
