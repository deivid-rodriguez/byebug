begin
  require 'pry'
  has_pry = true
rescue LoadError
  has_pry = false
end

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
        return errmsg('Command is available only in local mode.')
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
end if has_pry
