module Byebug
  class PostMortemSetting < Setting
    def help
      'Enable/disable post-mortem mode'
    end

    def value=(v)
      v ? Byebug.post_mortem : Byebug.post_mortem = v
    end

    def value
      Byebug.post_mortem?
    end
  end
end
