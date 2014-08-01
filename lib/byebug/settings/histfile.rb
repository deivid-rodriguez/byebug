module Byebug
  class HistfileSetting < Setting
    DEFAULT = File.expand_path("#{ENV['HOME'] || '.'}/.byebug_hist")

    def help
      "Customize file where history is loaded from and saved to. By default, " \
      "~/.byebug_hist"
    end

    def to_s
      "The command history file is #{value}\n"
    end
  end
end
