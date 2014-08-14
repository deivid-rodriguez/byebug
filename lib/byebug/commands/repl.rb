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

      cont = IRB.start(__FILE__)
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

  begin
    require 'pry'
    has_pry = true
  rescue LoadError
    has_pry = false
  end

  class PryCommand < Command
    def regexp
      /^\s* pry \s*$/x
    end

    def execute
      unless @state.interface.kind_of?(LocalInterface)
        print "Command is available only in local mode.\n"
        throw :debug_error
      end

      get_binding.pry
    end

    class << self
      def names
        %w(pry)
      end

      def description
        %{pry\tstarts a Pry session.}
      end
    end
  end if has_pry
end
