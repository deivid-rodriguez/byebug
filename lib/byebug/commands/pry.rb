begin
  require 'pry'
  has_pry = true
rescue LoadError
  has_pry = false
end

module Byebug
  class PryCommand < Command
    def regexp
      /^\s* pry \s*$/x
    end

    def execute
      unless @state.interface.is_a?(LocalInterface)
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
  end
end if has_pry
