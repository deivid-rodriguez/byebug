# encoding: utf-8
module Byebug

  # Mix-in module to assist in command parsing.
  module FrameFunctions
    def c_frame?(frame_no)
      @state.context.frame_binding(frame_no).nil?
    end

    def switch_to_frame(frame_no)
      if frame_no < 0
        abs_frame_no = Context.stack_size + frame_no
      else
        abs_frame_no = frame_no
      end
    end

    def navigate_to_frame(jump_no)
      return if jump_no == 0
      total_jumps, current_jumps, new_pos = jump_no.abs, 0, @state.frame_pos
      step = jump_no/total_jumps
      loop do
        new_pos += step
        return new_pos if new_pos < 0 || new_pos >= Context.stack_size

        next if c_frame?(new_pos)

        current_jumps += 1
        break if current_jumps == total_jumps
      end
      return new_pos
    end

    def adjust_frame(frame_pos, absolute)
      if absolute
        abs_frame_pos = switch_to_frame(frame_pos)
        return errmsg "Can't navigate to c-frame\n" if c_frame?(abs_frame_pos)
      else
        abs_frame_pos = navigate_to_frame(frame_pos)
      end

      return errmsg "Can't navigate beyond the oldest frame\n" if
        abs_frame_pos >= Context.stack_size
      return errmsg "Can't navigate beyond the newest frame\n" if
        abs_frame_pos < 0

      @state.frame_pos = abs_frame_pos
      @state.file = @state.context.frame_file @state.frame_pos
      @state.line = @state.context.frame_line @state.frame_pos
      @state.previous_line = nil
      ListCommand.new(@state).execute
    end

    def get_frame_class(style, pos)
      frame_class = style == :short ? '' : "#{@state.context.frame_class pos}"
      return frame_class == '' ? '' : "#{frame_class}."
    end

    def get_frame_block_and_method(pos)
      frame_deco_regexp = /((?:block(?: \(\d+ levels\))?|rescue) in )?(.+)/
      frame_deco_method = "#{@state.context.frame_method pos}"
      frame_block_and_method = frame_deco_regexp.match(frame_deco_method)[1..2]
      return frame_block_and_method.map{ |x| x.nil? ? '' : x }
    end

    def get_frame_args(style, pos)
      args = @state.context.frame_args pos
      return '' if args.empty?

      locals = @state.context.frame_locals pos if style == :long
      my_args = args.map do |arg|
        case arg[0]
          when :block
            prefix, default = '&', 'block'
          when :rest
            prefix, default = '*', 'args'
          else
            prefix, default = '', nil
        end
        klass = style == :long && arg[1] ? "##{locals[arg[1]].class}" : ''
        "#{prefix}#{arg[1] || default}#{klass}"
      end

      return "(#{my_args.join(', ')})"
    end

    def get_frame_call(prefix, pos)
      frame_block, frame_method = get_frame_block_and_method(pos)
      frame_class = get_frame_class(Command.settings[:callstyle], pos)
      frame_args = get_frame_args(Command.settings[:callstyle], pos)

      call_str = frame_block + frame_class + frame_method + frame_args

      max_call_str_size = Command.settings[:width] - prefix.size
      if call_str.size > max_call_str_size
        call_str = call_str[0..max_call_str_size - 5] + "...)"
      end

      return call_str
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

    def print_frame(pos, mark_current = true)
      file = @state.context.frame_file pos
      line = @state.context.frame_line pos

      unless Command.settings[:fullpath]
        path_components = file.split(/[\\\/]/)
        if path_components.size > 3
          path_components[0...-3] = '...'
          file = path_components.join(File::ALT_SEPARATOR || File::SEPARATOR)
        end
      end

      if mark_current
        frame_str = (pos == @state.frame_pos) ? '--> ' : '    '
      else
        frame_str = ""
      end
      frame_str += c_frame?(pos) ? ' ͱ-- ' : ''

      frame_str += sprintf "#%-2d ", pos
      frame_str += get_frame_call frame_str, pos
      file_line = "at #{CommandProcessor.canonic_file(file)}:#{line}"
      if frame_str.size + file_line.size + 1 > Command.settings[:width]
        frame_str += "\n      #{file_line}\n"
      else
        frame_str += " #{file_line}\n"
      end

      print frame_str
    end
  end

  # Implements byebug "where" or "backtrace" command.
  class WhereCommand < Command
    def regexp
      /^\s* (?:w(?:here)?|bt|backtrace) \s*$/x
    end

    def execute
      print_backtrace
    end

    class << self
      def names
        %w(where backtrace)
      end

      def description
        %{w[here]|bt|backtrace\tdisplay stack frames

          Print the entire stack frame. Each frame is numbered; the most recent
          frame is 0. A frame number can be referred to in the "frame" command;
          "up" and "down" add or subtract respectively to frame numbers shown.
          The position of the current frame is marked with -->. C-frames hang
          from their most immediate Ruby frame to indicate that they are not
          navigable}
      end
    end
  end

  class UpCommand < Command
    def regexp
      /^\s* u(?:p)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      pos = get_int(@match[1], "Up")
      return unless pos
      adjust_frame(pos, false)
    end

    class << self
      def names
        %w(up)
      end

      def description
        %{up[ count]\tmove to higher frame}
      end
    end
  end

  class DownCommand < Command
    def regexp
      /^\s* down (?:\s+(\S+))? \s*$/x
    end

    def execute
      pos = get_int(@match[1], "Down")
      return unless pos
      adjust_frame(-pos, false)
    end

    class << self
      def names
        %w(down)
      end

      def description
        %{down[ count]\tmove to lower frame}
      end
    end
  end

  class FrameCommand < Command
    def regexp
      /^\s* f(?:rame)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      return print_frame @state.frame_pos unless @match[1]
      return unless pos = get_int(@match[1], "Frame")
      adjust_frame(pos, true)
    end

    class << self
      def names
        %w(frame)
      end

      def description
        %{f[rame][ frame-number]

          Move the current frame to the specified frame number, or the 0 if no
          frame-number has been given.

          A negative number indicates position from the other end, so "frame -1"
          moves to the oldest frame, and "frame 0" moves to the newest frame.

          Without an argument, the command prints the current stack frame. Since
          the current position is redisplayed, it may trigger a resyncronization
          if there is a front end also watching over things.}
      end
    end
  end
end
