# frozen_string_literal: true

require_relative "../setting"

module Byebug
  #
  # Setting to toggle the exit prompt
  #
  class PromptOnExitSetting < Setting
    DEFAULT = true

    def banner
      "Display exit prompt when quitting"
    end

    def to_s
      "Exit prompt enabled? #{value}\n"
    end
  end
end
