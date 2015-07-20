require 'byebug/command'
require 'byebug/helpers/eval'

module Byebug
  #
  # Enter Pry from byebug's prompt
  #
  class PryCommand < Command
    include Helpers::EvalHelper

    def regexp
      /^\s* pry \s*$/x
    end

    def description
      <<-EOD
        pry

        #{short_description}
      EOD
    end

    def short_description
      'Starts a Pry session'
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

      default_binding.pry
    end
  end
end
