require 'byebug/setting'

module Byebug
  #
  # Setting to customize the file where byebug's history is saved.
  #
  class SavefileSetting < Setting
    DEFAULT = File.expand_path("#{ENV['HOME'] || '.'}/.byebug_save")

    def banner
      <<-EOB
        File where save commands saves current settings to. Default:
        ~/.byebug_save
      EOB
    end

    def to_s
      "The command history file is #{value}\n"
    end
  end
end
