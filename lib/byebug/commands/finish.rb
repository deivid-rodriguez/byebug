require 'byebug/command'
require 'byebug/helpers/parse'

module Byebug
  #
  # Implements the finish functionality.
  #
  # Allows the user to continue execution until certain frames are finished.
  #
  class FinishCommand < Command
    include Helpers::ParseHelper

    self.allow_in_post_mortem = false

    def regexp
      /^\s* fin(?:ish)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      max_frames = @state.context.stack_size - @state.frame
      if @match[1]
        n_frames, err = get_int(@match[1], 'finish', 0, max_frames - 1)
        return errmsg(err) unless n_frames
      else
        n_frames = 1
      end

      force = n_frames == 0 ? true : false
      @state.context.step_out(@state.frame + n_frames, force)
      @state.frame = 0
      @state.proceed
    end

    def description
      <<-EOD
        fin[ish][ n_frames]

        Execute until frame returns.

        If no number is given, we run until the current frame returns. If a
        number of frames `n_frames` is given, then we run until `n_frames`
        return from the current position.
      EOD
    end
  end
end
