module Byebug
  #
  # Setting to customize the file where byebug's history is saved.
  #
  class HistfileSetting < Setting
    DEFAULT = File.expand_path("#{ENV['HOME'] || '.'}/.byebug_hist")

    def banner
      'File where cmd history is saved to. Default: ~/.byebug_hist'
    end

    def to_s
      "The command history file is #{value}\n"
    end
  end
end
