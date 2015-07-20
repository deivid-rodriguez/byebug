module Byebug
  module Helpers
    #
    # Utilities to assist frame navigation
    #
    module FrameHelper
      def adjust_frame(frame, absolute)
        if absolute
          new_frame = index_from_start(frame)

          return frame_err('c_frame') if Frame.new(context, new_frame).c_frame?
        else
          new_frame = navigate_to_frame(frame)
        end

        return frame_err('too_low') if new_frame >= context.stack_size
        return frame_err('too_high') if new_frame < 0

        context.frame = new_frame
        processor.prev_line = nil
      end

      private

      def navigate_to_frame(jump_no)
        return if jump_no == 0

        current_jumps = 0
        current_pos = context.frame.pos

        loop do
          current_pos += direction(jump_no)
          break if current_pos < 0 || current_pos >= context.stack_size

          next if Frame.new(context, current_pos).c_frame?

          current_jumps += 1
          break if current_jumps == jump_no.abs
        end

        current_pos
      end

      def frame_err(msg)
        errmsg(pr("frame.errors.#{msg}"))
      end

      #
      # @param [Integer] A positive or negative integer
      #
      # @return [Integer] +1 if step is positive / -1 if negative
      #
      def direction(step)
        step / step.abs
      end

      #
      # Convert a possibly negative index to a positive index from the start
      # of the callstack. -1 is the last position in the stack and so on.
      #
      # @param [Integer] Integer to be converted in a proper positive index.
      #
      def index_from_start(i)
        i >= 0 ? i : context.stack_size + i
      end
    end
  end
end
