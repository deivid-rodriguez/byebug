module Byebug
  class PostMortemSetting < Setting
    def initialize
      Byebug.post_mortem = DEFAULT
    end

    def help
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
    context = Byebug.raised_exception.__bb_context
    file    = Byebug.raised_exception.__bb_file
    line    = Byebug.raised_exception.__bb_line
    Byebug.handler.at_line(context, file, line)
  end

  at_exit { Byebug.handle_post_mortem if Byebug.post_mortem? }
end
