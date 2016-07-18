require 'byebug/setting'
require 'linecache2'

module Byebug
  #
  # Setting to customize whether source-code listings use terminal colors.
  #
  class HighlightSetting < Setting
    DEFAULT = :plain

    def banner
      'Set whether we use terminal highlighting'
    end

    def value=(v)
      v = v.to_sym
      if [:dark, :light, :plain].member?(v)
        LineCache.clear_file_format_cache
        @value = v
      else
        puts("Highlight style should be either 'light', 'dark', or 'plain'")
      end
    end

    def to_s
      "Highlight style is '#{value}'"
    end
  end
end
