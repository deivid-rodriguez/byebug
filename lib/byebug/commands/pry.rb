module Byebug
  #
  # Enter Pry from byebug's prompt
  #
  class PryCommand < Command
    def regexp
      /^\s* pry \s*$/x
    end

    def execute
      unless @state.interface.is_a?(LocalInterface)
        return errmsg(pr('base.errors.only_local'))
      end

      get_binding.pry
    end

    class << self
      def names
        %w(pry)
      end

      def description
        %(pry        Starts a Pry session.)
      end
    end
  end
end if defined?(Pry)
