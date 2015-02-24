require 'byebug/command'

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

      begin
        require 'pry'
      rescue LoadError
        errmsg(pr('pry.errors.not_installed'))
      end

      get_binding.pry
    end

    class << self
      def names
        %w(pry)
      end

      def description
        prettify <<-EOD
          pry  Starts a Pry session.
        EOD
      end
    end
  end
end
