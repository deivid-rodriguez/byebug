require 'pathname'
require 'byebug/command'
require 'byebug/helpers/frame'
require 'byebug/helpers/parse'

module Byebug
  #
  # Move the current frame down in the backtrace.
  #
  class DownCommand < Command
    include Helpers::FrameHelper
    include Helpers::ParseHelper

    def regexp
      /^\s* down (?:\s+(\S+))? \s*$/x
    end

    def description
      <<-EOD
        down[ count]

        #{short_description}

        Use the "bt" command to find out where you want to go.
      EOD
    end

    def short_description
      'Moves to a lower frame in the stack trace'
    end

    def execute
      pos, err = parse_steps(@match[1], 'Down')
      return errmsg(err) unless pos

      adjust_frame(-pos, false)

      ListCommand.new(@state).execute if Setting[:autolist]
    end
  end
end
