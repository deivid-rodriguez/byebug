module Byebug
  module Helpers
    #
    # Utilities to assist frame navigation
    #
    module FrameHelper
      def switch_to_frame(frame_no)
        frame_no >= 0 ? frame_no : @state.context.stack_size + frame_no
      end

      def navigate_to_frame(jump_no)
        return if jump_no == 0

        current_jumps = 0
        current_pos = @state.frame

        loop do
          current_pos += direction(jump_no)
          break if current_pos < 0 || current_pos >= @state.context.stack_size

          next if @state.c_frame?(current_pos)

          current_jumps += 1
          break if current_jumps == jump_no.abs
        end

        current_pos
      end

      def adjust_frame(frame, absolute)
        if absolute
          abs_frame = switch_to_frame(frame)
          if @state.c_frame?(abs_frame)
            return errmsg(pr('frame.errors.c_frame'))
          end
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
      end

      def get_pr_arguments(frame_no)
        file = @state.frame_file(frame_no)
        full_path = File.expand_path(file)
        line = @state.frame_line(frame_no)
        call = @state.frame_call(frame_no)
        mark = @state.frame_mark(frame_no)
        pos = @state.frame_pos(frame_no)

        { mark: mark, pos: pos, call: call, file: file, line: line,
          full_path: full_path }
      end

      private

      #
      # @param [Integer] A positive or negative integer
      #
      # @return [Integer] +1 if step is positive / -1 if negative
      #
      def direction(step)
        step / step.abs
      end
    end
  end
end
