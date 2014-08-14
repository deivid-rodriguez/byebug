require 'irb'

module Byebug
  class IrbCommand < Command
    def regexp
      /^\s* irb \s*$/x
    end

    def execute
      unless @state.interface.kind_of?(LocalInterface)
        print "Command is available only in local mode.\n"
        throw :debug_error
      end

      IRB.start(__FILE__)
    end

    class << self
      def names
        %w(irb)
      end

      def description
        %{irb\tstarts an Interactive Ruby (IRB) session.}
      end
    end
  end
end
