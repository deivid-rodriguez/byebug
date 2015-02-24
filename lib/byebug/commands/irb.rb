require 'byebug/command'
require 'irb'

module Byebug
  #
  # Enter IRB from byebug's prompt
  #
  class IrbCommand < Command
    def regexp
      /^\s* irb \s*$/x
    end

    def execute
      unless @state.interface.is_a?(LocalInterface)
        return errmsg(pr('base.errors.only_local'))
      end

      IRB.start(__FILE__)
    end

    class << self
      def names
        %w(irb)
      end

      def description
        prettify <<-EOD
          irb  Starts an Interactive Ruby (IRB) session.
        EOD
      end
    end
  end
end
