require 'byebug/setting'

module Byebug
  #
  # Setting to enable/disable post_mortem mode, i.e., a debugger prompt after
  # program termination by unhandled exception.
  #
  class PostMortemSetting < Setting
    def initialize
      Byebug.post_mortem = DEFAULT
    end

    def banner
      'Enable/disable post-mortem mode'
    end

    def value=(v)
      Byebug.post_mortem = v
    end

    def value
      Byebug.post_mortem?
    end
  end

  #
  # Saves information about the unhandled exception and gives a byebug
  # prompt back to the user before program termination.
  #
  def self.handle_post_mortem
    return unless Byebug.raised_exception

    context = Byebug.raised_exception.__bb_context
    file = Byebug.raised_exception.__bb_file
    line = Byebug.raised_exception.__bb_line

    Byebug.handler.at_line(context, file, line)
  end

  at_exit { Byebug.handle_post_mortem if Byebug.post_mortem? }
end
