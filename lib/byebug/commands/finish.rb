module Byebug

  # Implements byebug's 'finish' command.
  class FinishCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* fin(?:ish)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      max_frames = Context.stack_size - @state.frame_pos
      n_frames = get_int(@match[1], 'finish', 0, max_frames - 1, 1)
      return nil unless n_frames

      force = n_frames == 0 ? true : false
      @state.context.step_out(@state.frame_pos + n_frames, force)
      @state.frame_pos = 0
      @state.proceed
    end

    class << self
      def names
        %w(finish)
      end

      def description
        %{fin[ish][ n_frames]\tExecute until frame returns.

          If no number is given, we run until the current frame returns. If a
          number of frames `n_frames` is given, then we run until `n_frames`
          return from the current position.}
      end
    end
  end
end
