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
        return errmsg('Command is available only in local mode.')
      end

      IRB.start(__FILE__)
    end

    class << self
      def names
        %w(irb)
      end

      def description
        %{irb        Starts an Interactive Ruby (IRB) session.}
      end
    end
  end
end
