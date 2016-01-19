# frozen_string_literal: true
require 'byebug/setting'

module Byebug
  #
  # Setting to customize the verbosity level for stack frames.
  #
  class CallstyleSetting < Setting
    DEFAULT = 'long'.freeze

    def banner
      'Set how you want method call parameters to be displayed'
    end

    def to_s
      "Frame display callstyle is '#{value}'"
    end
  end
end
