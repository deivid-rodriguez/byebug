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

    def description
      <<-EOD
        irb

        #{short_description}
      EOD
    end

    def short_description
      'Starts an IRB session'
    end

    def execute
      unless @state.interface.is_a?(LocalInterface)
        return errmsg(pr('base.errors.only_local'))
      end

      IRB.start(__FILE__)
    end
  end
end
