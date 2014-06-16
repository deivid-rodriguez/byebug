module Byebug
  class PostMortemSetting < Setting
    def help
      'Enable/disable post-mortem mode'
    end

    def value=(v)
      Byebug.post_mortem = v
      at_exit { handle_post_mortem if Byebug.post_mortem? }
    end

    def value
      Byebug.post_mortem?
    end

    private
      #
      # Saves information about the unhandled exception and gives a byebug
      # prompt back to the user before program termination.
      #
      def handle_post_mortem
        context = Byebug.raised_exception.__bb_context
        file    = Byebug.raised_exception.__bb_file
        line    = Byebug.raised_exception.__bb_line
        Byebug.handler.at_line(context, file, line)
      end
  end
end
