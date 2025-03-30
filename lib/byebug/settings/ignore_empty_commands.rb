# frozen_string_literal: true

require_relative "../setting"

module Byebug
  #
  # Setting to control what Byebug does when the user enters an empty
  # command (presses enter without a command).
  #
  class IgnoreEmptyCommandsSetting < Setting
    DEFAULT = false

    def banner
      "Enable/disable running the last command upon empty commands"
    end
  end
end
